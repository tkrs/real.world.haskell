import           Control.Monad      (when)
import           Data.List
import           System.Environment (getArgs)
import           System.Exit
import           System.IO

main :: IO ()
main = do
  args <- getArgs

  when (length args /= 2) $ do
    putStrLn "Syntax: passwd-al filename uid"
    exitFailure

  content <- readFile (args !! 0)

  let username = findByUID content (read (args !! 1))

  case username of
         Just x -> putStrLn x
         Nothing -> putStrLn "Could not find that UID"


findByUID :: String -> Integer -> Maybe String
findByUID content uid =
  let al = map parseline . lines $ content
  in lookup uid al

parseline :: String -> (Integer, String)
parseline input =
  let fields = split ':' input
  in (read (fields !! 2), fields !! 0)

split :: Eq a => a -> [a] -> [[a]]
split _ [] = []
split delim str =
  let (before, remainder) = span (/= delim) str
  in before : case remainder of
               [] -> []
               x -> split delim (tail x)
