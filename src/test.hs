#!/usr/bin/env stack
{- stack --install-ghc
    runghc
    --package amqp
-}

import Data.Dates (DateTime, pDateTime, parseDate,getCurrentDateTime)
import Text.Parsec
import Text.Parsec.String (Parser)

somewhere :: Parser a -> Parser a
somewhere p = try p <|> (anyChar >> somewhere p)

parseDateLiberal :: DateTime -> String -> Either ParseError DateTime
parseDateLiberal now str =
  let
    p = somewhere $ pDateTime now
  in parse p "" str

testString = "\"Sun, 08 Jan 2017 20:40:45 +0000\""

main = do
  now <- getCurrentDateTime
  print $ parseDate now testString -- doesn't parse
  print $ parseDateLiberal now testString
