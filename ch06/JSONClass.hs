{-# LANGUAGE TypeSynonymInstances #-}

module JSONClass where

import Control.Arrow (second)

-- import SimpleJSON

type JSONError = String

class JSON a where
  toJValue :: a -> JValue
  fromJValue :: JValue -> Either JSONError a

newtype JAry a = JAry {
  fromJAry :: [a]
  } deriving (Eq, Ord, Show)

newtype JObj a = JObj {
  fromJObj :: [(String, a)]
  } deriving (Eq, Ord, Show)

data JValue = JString String
            | JNumber Double
            | JBool Bool
            | JNull
            | JObject (JObj JValue)
            | JArray (JAry JValue)
              deriving (Eq, Ord, Show)

instance JSON JValue where
  toJValue = id
  fromJValue = Right

instance JSON Bool where
  toJValue = JBool
  fromJValue (JBool b) = Right b
  fromJValue _ = Left "not a JSON boolean"

instance JSON String where
  toJValue = JString
  fromJValue (JString s) = Right s
  fromJValue _ = Left "not a JSON string"

doubleToJValue :: (Double -> a) -> JValue -> Either JSONError a
doubleToJValue f (JNumber v) = Right (f v)
doubleToJValue _ _ = Left "not a JSON number"

instance JSON Int where
  toJValue = JNumber . realToFrac
  fromJValue = doubleToJValue round

instance JSON Integer where
  toJValue = JNumber . realToFrac
  fromJValue = doubleToJValue round

instance JSON Double where
  toJValue = JNumber
  fromJValue = doubleToJValue id

instance (JSON a) => JSON [a] where
  toJValue = undefined
  fromJValue = undefined

jaryFromJValue :: (JSON a) => JValue -> Either JSONError (JAry a)
jaryToJValue :: JAry a -> JValue

instance (JSON a) => JSON (JAry a) where
  toJValue = jaryToJValue
  fromJValue = jaryFromJValue

listToJValue :: (JSON a) => [a] -> [JValue]
listToJValue = map toJValue

jvaluesToJAry :: [JValue] -> JAry JValue
jvaluesToJAry = JAry

jaryOfJValuesToJValue :: JAry JValue -> JValue
jaryOfJValuesToJValue = JArray

jaryToJValue = JArray . JAry . map toJValue . fromJAry

jaryFromJValue (JArray (JAry a)) =
  whenRight JAry (mapEithers fromJValue a)
jaryFromJValue _ = Left "not a JSON array"

whenRight :: (b -> c) -> Either a b -> Either a c
whenRight _ (Left err) = Left err
whenRight f (Right a) = Right (f a)

mapEithers :: (a -> Either b c) -> [a] -> Either b [c]
mapEithers f (x:xs) = case mapEithers f xs of
                           Left err -> Left err
                           Right ys -> case f x of
                                            Left err -> Left err
                                            Right y -> Right (y:ys)
mapEithers _ _ = Right []

  
instance (JSON a) => JSON (JObj a) where
  toJValue = JObject . JObj . map (second toJValue) . fromJObj
  fromJValue (JObject (JObj o)) = whenRight JObj (mapEithers unwrap o)
    where unwrap (k, v) = whenRight ((,) k) (fromJValue v)
  fromJValue _ = Left "not a JSON object"
