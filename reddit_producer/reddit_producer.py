#TODO: add the comments to kafkaproducer
#TODO: add logs and error handling
from json import dumps
from kafka import KafkaProducer
import configparser
import praw
import time

class RedditProducer:

    def __init__(self, subreddit_name: str, cred_file: str="secrets/credentials.cfg"):

        self.subreddit_name = subreddit_name
        self.reddit = self.__get_reddit_client__(cred_file)
        self.producer = KafkaProducer(bootstrap_servers=['kafkaservice:9092'],
                            value_serializer=lambda x:
                            dumps(x).encode('utf-8')
                        )


    def __get_reddit_client__(self, cred_file) -> praw.Reddit:

        config = configparser.ConfigParser()
        config.read_file(open(cred_file))

        try:
            client_id: str = config.get("reddit", "client_id")
            client_secret: str = config.get("reddit", "client_secret")
            user_agent: str = config.get("reddit", "user_agent")
        except configparser.NoSectionError:
            raise ValueError("The config file does not contain a reddit credential section.")
        except configparser.NoOptionError as e:
            raise ValueError(f"The config file is missing the option {e}")
        
        return praw.Reddit(
            user_agent = user_agent,
            client_id = client_id,
            client_secret = client_secret
        )


    def start_stream(self) -> None:
        subreddit = self.reddit.subreddit(self.subreddit_name)
        comment: praw.models.Comment
        for comment in subreddit.stream.comments(skip_existing=True):
            try:
                comment_json: dict[str, str] = {
                    "id": comment.id,
                    "name": comment.name,
                    "author": comment.author.name,
                    "body": comment.body,
                    "subreddit": comment.subreddit.display_name,
                    "upvotes": comment.ups,
                    "downvotes": comment.downs,
                    "over_18": comment.over_18,
                    "timestamp": comment.created_utc,
                    "permalink": comment.permalink,
                }
                
                #! for debugging
                self.producer.send("redditcomments", value=comment_json)
                print("producing comments: ", comment_json)
                time.sleep(0.1) # throttle due to massive amount of comments (r/all)
            except:
                # Handle errors
                pass

if __name__ == "__main__":
    reddit_producer = RedditProducer('all')
    reddit_producer.start_stream()
