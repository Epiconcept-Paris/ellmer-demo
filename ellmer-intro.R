
# First time setup: 

## Download, install and setup ollama. Copy and paste this link into your browser
# https://ollama.com/download


## Download some starter models (Qwen3-4B, etc)
# Open ollama and in the drop down next to the chat window, select the models and try to
# 'chat' with them. A download will start.

## Install the ellmer package
# install.packages("ellmer") ### Run this line (remove #)


# Using ellmer:

## Load the package
library(ellmer)
library(dplyr)

## Find out which models you've already got downloaded
models_ollama()

## Create an LLM instance, including a 'system prompt' that describes
## an expert SARI case assistant
chat <- chat_ollama(
  model = "qwen3:4b",
  system_prompt = "You are a terse and helpful assistant."
)

## Run the model in an interactive chat window (Console)
live_console(chat)

### PRESS Q TO EXIT THE CHAT

## Run the model outside of a chat window
b<-chat$chat("What's your name?")


# ACTIVITY: ENTITY EXTRACTION (NLP) WITH AN LLM (BSI example)


# Interacting with the LLM programatically

## Example activity: We'd like to extract some key information from patient
## notes relating to when and what was cultured in cases of bacteremia.

#' For this exercise, we have a dummy dataset containing notes and the results 
#' of human labelling. Things like specimen collection date, and what was 
#' cultured were extracted by a human already (to create our evaluation corpus)

## First, lets load that dataset
dummy_data <- read.csv("data/BSI_testing_data.csv")

# Take a look at a note
cat(dummy_data$patient_note[1])

# What was cultured?
cat(dummy_data$causative[1])


## Next, lets make a system prompt for our LLM
prompt_causative <- c("You are a helpful AI assistant that extracts from 
                      patient notes the causative specimens that might have 
                      been identfied after bacterial culturing to diagnose 
                      bloodstream infections. You return only the baceteria 
                      name, if present, and take care to only return the name 
                      of the relevant causative agent.")


# Then we'll test our prompt with record 1

## Create the LLM chat object again, this time with our new system prompt
base_chat <- chat_ollama(
  model = "qwen3:4b",
  system_prompt = prompt_causative
)

# Test with record 1
b<-base_chat$chat(paste0("Please extract the causative specimen cultured in this note:", dummy_data$patient_note[1]))

# Human vs LLM result
cat("\n \n","Human label:",dummy_data$causative[1],"\n \n","LLM label:",b)



# Now we'll programatically loop over the first 25 records with pathogens, ask 
# the LLM to extract causative organism, and then add that back 
# to the dataset for review


# Has a causative organism in note
activity_data <- dummy_data %>%
  filter(causative!="None")

# First 25 records only
activity_data <- activity_data[1:25, ]

# Make the result column
activity_data$result <- NA_character_

# Loop over every note and run the LLM
for (n_note in seq_len(nrow(activity_data))) {
  
  # Make a new 'subchat' so that we're not adding too much context
  chat_i <- base_chat$clone()$set_turns(list())  # wipe history
  
  # For this patient note
  p_note <- activity_data$patient_note[n_note]
  

  
  # Supply the request and note itself
  prompt <- paste0(
    "Extract the causative specimen cultured. Return ONE organism name only, or NA.\n\n",
    "NOTE:\n```text\n", p_note, "\n```"
  )
  
  # Run the LLM and request labelling
  # Save the result in the 'result' column
  activity_data$result[n_note] <- chat_i$chat(prompt)
  
}


# Save the dataset with LLM response
write.csv(result_data,"data/results_llm.csv")




#### What do the results show? Does the LLM agree with the human labeller?
#### How do the outputs differ? There is likely some work required in terms of
#### making the formats/spellings match to calculate agreement (or fuzzymatch)


