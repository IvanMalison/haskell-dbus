-- Copyright (C) 2009-2012 John Millikin <jmillikin@gmail.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

module DBus.Util
	( hexToInt
	, maybeIndex
	, readUntil
	, dropEnd
	, void
	, untilM
	, parseBytes
	) where

import qualified Data.ByteString.Char8 as Char8
import           Data.Char (digitToInt)
import           Data.List (isPrefixOf)

import           Text.ParserCombinators.Parsec (Parser, runParser)

hexToInt :: String -> Int
hexToInt = foldl ((+) . (16 *)) 0 . map digitToInt

maybeIndex :: [a] -> Int -> Maybe a
maybeIndex (x:_ ) 0         = Just x
maybeIndex (_:xs) n | n > 0 = maybeIndex xs (n - 1)
maybeIndex _ _ = Nothing

-- | Read values from a monad until a guard value is read; return all
-- values, including the guard.
--
readUntil :: (Monad m, Eq a) => [a] -> m a -> m [a]
readUntil guard getx = readUntil' [] where
	guard' = reverse guard
	step xs | isPrefixOf guard' xs = return . reverse $ xs
	        | otherwise            = readUntil' xs
	readUntil' xs = do
		x <- getx
		step $ x:xs

-- | Drop /n/ items from the end of a list
dropEnd :: Int -> [a] -> [a]
dropEnd n xs = take (length xs - n) xs

void :: Monad m => m a -> m ()
void m = m >> return ()

untilM :: Monad m => m Bool -> m a -> m [a]
untilM test comp = do
	done <- test
	if done
		then return []
		else do
			x <- comp
			xs <- untilM test comp
			return (x:xs)

parseBytes :: Parser a -> Char8.ByteString -> Maybe a
parseBytes p bytes = case runParser p () "" (Char8.unpack bytes) of
	Left _ -> Nothing
	Right a -> Just a
