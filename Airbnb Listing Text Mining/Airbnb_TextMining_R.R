#installing and loading the mongolite library to download the Airbnb data
#install.packages("mongolite") #need to run this line of code only once and then you can comment out
#install.packages("qdapDictionaries")
library(qdapDictionaries)
library(mongolite)
library(tidytext)
library(janeaustenr)
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)
library(widyr)
library(ggraph)
library(igraph)
library(textcat)
library(Matrix)

english_words <- GradyAugmented

# connection string to MongoDB
connection_string <- 'mongodb+srv://----
airbnb_collection <- mongo(collection="listingsAndReviews", db="sample_airbnb", url=connection_string)

#Here's how you can download all the Airbnb data from Mongo
## keep in mind that this is huge and you need a ton of RAM memory

airbnb_all <- airbnb_collection$find()

#######################################################
#if you know or want to learn MQL (MongoQueryLanguage), that is a JSON syntax, feel free to use the following:::
######################################################
#1 subsetting your data based on a condition:
mydf <- airbnb_collection$find('{"bedrooms":2, "price":{"$gt":50}}')

#2 writing an analytical query on the data::
mydf_analytical <- airbnb_collection$aggregate('[{"$group":{"_id":"$room_type", "avg_price": {"$avg":"price"}}}]')
head(airbnb_all$description)

# changing colname "description" to "text"
colnames(airbnb_all)[5] <- "text"

# Filtering to host_location in United States and executing tokenization
airbnb_token <- airbnb_all %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  filter(word %in% english_words) %>%
  count(word, sort=T)


##############
# SENTIMENTS #
##############
# nrc sentiments
nrc_sentiments <- airbnb_token %>%
  inner_join(get_sentiments("nrc"), by = "word") %>%
  count(sentiment, wt = n, sort = TRUE)
nrc_sentiments

# afinn sentiments
afinn_avg_sentiment <- airbnb_token %>%
  inner_join(get_sentiments("afinn"), by = "word") %>%
  summarise(avg_sentiment = sum(value * n) / sum(n)) 
afinn_avg_sentiment



#################### 
# creating bigrams #
#################### 
airbnb_bigrams <- airbnb_all %>%
  unnest_tokens(bigram, text, token = "ngrams", n=2) %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word) %>%
  filter(word1 %in% english_words) %>%
  filter(word2 %in% english_words) %>%
  count(word1, word2, sort = TRUE)
airbnb_bigrams

########################
# creating quadrograms #
########################
airbnb_quadrogram <- airbnb_all %>%
  unnest_tokens(quadrogram, text, token = "ngrams", n=4) %>%
  separate(quadrogram, c("word1", "word2", "word3", "word4"), sep=" ") %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word) %>%
  filter(!word3 %in% stop_words$word) %>%
  filter(!word4 %in% stop_words$word) %>%
  filter(word1 %in% english_words) %>%
  filter(word2 %in% english_words) %>%
  filter(word3 %in% english_words) %>%
  filter(word4 %in% english_words) %>%
  count(word1, word2, word3, word4, sort=T)
airbnb_quadrogram

# filtering for top 2000 quadrograms
top_quadrograms <- airbnb_quadrogram %>%
  slice_max(n, n = 2000) %>%
  unite(quadrogram, word1, word2, word3, word4, sep = " ") %>%
  pull(quadrogram)

########################
# CREATING CORRELATION #
########################
my_tidy_df <- airbnb_all %>%
  unnest_tokens(word, text) %>%
  filter(!word %in% stop_words$word) %>%
  filter(word %in% english_words)

#taking out the least common words
word_cors <- my_tidy_df %>%
  group_by(word) %>%
  filter(n() >= 4) %>%
  filter(word %in% english_words) %>%
  pairwise_cor(word, listing_url, sort=TRUE)

# filtering for less correlation because "T&C-words"
word_cors_filtered <- word_cors %>%
  filter(correlation < 0.99) %>%
  arrange(desc(correlation)) %>%
  slice(1:500,)
print(word_cors_filtered, n=200)


# Checking correlation for certain words
cor_filter <- word_cors %>%
  filter(item1 %in% c("beach", "city", "private", "pool", "business")) %>%
  group_by(item1) %>%
  ungroup() %>%
  mutate(item2 = reorder(item2, correlation))
print(cor_filter, n=30)

# creating correlation network plot
word_cors_filtered %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  geom_edge_link(aes(edge_alpha = correlation), show.legend = FALSE) +
  geom_node_point(color = "lightpink", size = 5) +
  geom_node_text(aes(label = name), repel = TRUE) +
  theme_void() +
  labs(title = "Word Correlation Network in Airbnb Listings")




######################################
# Connecting tokens and and numerics #
######################################

airbnb_tokens <- airbnb_all %>%
  select(listing_url, text, price, accommodates, bedrooms) %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words, by = "word") %>%
  filter(word %in% english_words) %>%  # keep only English words
  filter(str_detect(word, "[a-z]"))     # exclude numeric/punctuation artifacts

word_freq <- airbnb_tokens %>%
  count(listing_url, word) %>%
  pivot_wider(names_from = word, values_from = n, values_fill = 0)

numeric_data <- airbnb_all %>%
  select(listing_url, price, accommodates, bedrooms)

combined_df <- numeric_data %>%
  inner_join(word_freq, by = "listing_url")

colnames(combined_df)

# Correlation matrix
cor_matrix <- combined_df %>%
  select(-listing_url) %>%
  slice(1:2000,)
  cor()

# Extract correlations between words and price (example)
price_correlations <- cor_matrix["price.x", ] %>%
  sort(decreasing = TRUE)

# View top correlations
head(price_correlations, 20)



################################
# Connecting BIGRAMS and PRICE #
################################
top_bigrams <- airbnb_bigrams %>%
  slice_max(n, n = 2000) %>%
  unite(bigram, word1, word2, sep = " ") %>%
  pull(bigram)

# Recreate listing-level bigram matrix with top 500 only
airbnb_bigrams_listing_small <- airbnb_all %>%
  select(listing_url, price, text) %>%
  unnest_tokens(bigram, text, token = "ngrams", n=2) %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>%
  filter(!word1 %in% stop_words$word,
         !word2 %in% stop_words$word,
         word1 %in% english_words,
         word2 %in% english_words) %>%
  unite(bigram, word1, word2, sep = " ") %>%
  filter(bigram %in% top_bigrams) %>%
  count(listing_url, bigram) %>%
  pivot_wider(names_from = bigram, values_from = n, values_fill = 0)

# Combine with numeric price
combined_small <- airbnb_all %>%
  select(listing_url, price) %>%
  inner_join(airbnb_bigrams_listing_small, by = "listing_url")

# Efficient correlation calculation
price_corr_small <- apply(combined_small %>% select(-listing_url, -price), 2,
                          function(x) cor(x, combined_small$price, use = "complete.obs"))

# View top correlated bigrams
head(sort(price_corr_small, decreasing = TRUE), 30)


# VISUALIZING top 30 corrleations of bigrams-price
top_bigrams_df <- data.frame(
  bigram = names(price_corr_small),
  correlation = as.numeric(price_corr_small)
  ) %>%
  arrange(desc(correlation))%>%
  slice(1:30)

# plotting
ggplot(top_bigrams_df, aes(x = reorder(bigram, correlation), y = correlation)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = round(correlation, 2)), hjust = -0.1, size = 3) +
  coord_flip() +
  theme_minimal(base_size = 12) +
  labs(title = "Top Airbnb Bigram Correlations with Price",
       subtitle = "Higher values indicate stronger association with higher prices",
       x = "Bigrams",
       y = "Correlation with Price") +
  theme(axis.text.y = element_text(size = 10))

