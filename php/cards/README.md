# cards
Very simple (and unfinished) package to play with cards

# Examples

Create new standard 52-cards deck and deal one hand with 13 cards:
```php
$deck = new Deck;
$hand1 = new Hand($deck, 13);
```
Sord hand (by default it is a bridge-type rank from ace (highest) to 2 (lowest), and from spades (highest) to clubs (lowest):
```php
$hand1->sort();
```
Pick a second and random card from the hand:
```php
$card1 = $hand1->pick(2);
$card2 = $hand1->rand();
```
Compare ranks of two cards:
```php
$hand->compare_rank($card1, $card2);
```
