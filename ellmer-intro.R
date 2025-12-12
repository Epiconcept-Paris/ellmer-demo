
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
dummy_data <- readxl::read_excel("data/BSI_testing_data.xlsx")

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
chat <- chat_ollama(
  model = "qwen3:4b",
  system_prompt = prompt_causative,
  echo = "output"
)

# Test with record 1
b<-chat$chat(paste0("Please extract the causative specimen cultured in this note:", dummy_data$patient_note[1]))

# Human vs LLM result
cat("\n \n","Human label:",dummy_data$causative[1],"\n \n","LLM label:",b)



# Now we'll programatically loop over all records, ask the LLM to extract
# causative organism, and then add that back to the dataset for review

# Make the result column
dummy_data$result <- ""

# Loop over every note and run the LLM
for (n_note in seq_len(nrow(dummy_data))) {
  
  # For this patient note
  p_note <- dummy_data$patient_note[n_note]
  
  # Run the LLM and request labelling
  llm_result <- chat$chat(paste0("Please extract the causative specimen cultured in this note:", p_note))
  
  # Save the result in the 'result' column
  dummy_data$result[n_note] <- llm_result
}

# Save the dataset with LLM response
write.csv(dummy_data,"results_llm.csv")



