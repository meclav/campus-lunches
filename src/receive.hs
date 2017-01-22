#!/usr/bin/env stack
{- stack --install-ghc
    runghc
    --package amqp
-}
--  scp /mnt/c/projects/haskell/receive.hs root@138.68.141.114:/app/src && ssh droplet stack /app/src/receive.hs
{-# LANGUAGE OverloadedStrings #-}

import Network.AMQP as AMQP
import Codec.MIME.Parse (parseMIMEMessage)
import Codec.MIME.Type as MIME
import qualified Data.Text as T

import Data.Either
import Data.Text.Lazy (toStrict)
import Data.Text.Lazy.Encoding (decodeUtf8)
import Data.Monoid ((<>))

import Control.Lens

import Text.Parsec
import Text.Parsec.String (Parser)

import Data.Dates (DateTime,pDateTime, parseDate, getCurrentDateTime)

-- We want to work with such values, will reject messages that we cannot parse into this form
data Email = Email {
  date :: DateTime,
  to :: T.Text,
  from :: T.Text,
  subject :: T.Text,
  content :: MIMEContent
} deriving (Show, Eq)

parseDateSubstring :: DateTime -> String -> Either ParseError DateTime
parseDateSubstring now str =
  let
    somewhere :: Parser a -> Parser a
    somewhere p = try p <|> (anyChar >> somewhere p)
    p = somewhere $ pDateTime now
  in parse p "" str

unpackMIMEValue :: DateTime -> MIME.MIMEValue -> Either String Email
unpackMIMEValue now MIME.MIMEValue { mime_val_content = content, mime_val_headers = headers }
  = let
      matchesParam name MIMEParam {paramName=paramName} = name == paramName
      paramVal MIMEParam {paramValue=v} = v
      extract fieldName =
        let
          relevantFields = map paramVal $ filter (matchesParam fieldName) headers
          listToEither [] = Left ("No MIME param named "++ fieldName)
          listToEither x:xs = Right x
        in listToEither relevantFields
      dateField = join $ fmap (parseDateSubstring now) $ fmap show $ extract "date"
      makeEmail (Right date, Right to, Right from, Right subject )
        = Right Email
          { date = date
          , to = to
          , from = from
          , subject = subject
          , content = content
        }
      makeEmail (d,t,f,s) = show $ lefts [d,t,f,s]

    in makeEmail (dateField, extract "to", extract "from", extract "subject")

main :: IO ()
main = do
     conn <- AMQP.openConnection "127.0.0.1" "/" "guest" "guest"
     ch   <- AMQP.openChannel conn

     now <- getCurrentDateTime
     putStrLn " [*] Waiting for messages. To exit press CTRL+C"
     AMQP.consumeMsgs ch "email" AMQP.NoAck (deliveryHandler now)

     -- waits for keypresses
     getLine
     AMQP.closeConnection conn

deliveryHandler :: DateTime -> (AMQP.Message, AMQP.Envelope) -> IO ()
deliveryHandler now (msg, metadata) =
  let messageText = decodeUtf8 $ msgBody msg
      message = parseMIMEMessage $ toStrict messageText
  in putStrLn $ show $ unpackMIMEValue now message
