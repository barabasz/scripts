<?php
/*
 * This is a very simple and unfinished package to play with 52-cards deck
 */
namespace Barabasz\Cards;

define('DEFAULT_SUIT_ORDER', ['clubs', 'diamonds', 'hearts', 'spades']);
define('DEFAULT_RANK_ORDER', [2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K', 'A']);

readonly class Card
{
    public int $s;
    public int $r;
    public string $suite;
    public string $rank;
    public string $rankname;
    public string $fullname;
    public string $suiteicon;
    public string $glyph;
    public string $symbol;

    public function __construct(int $suite, int $rank)
    {
        $this->s = $suite;
        $this->r = $rank;
        $this->suite = $this->get_card_suite($suite);
        $this->rank = $this->get_card_rank($rank);
        $this->rankname = $this->get_card_rankname($rank);
        $this->fullname = $this->rankname . ' of ' . $this->suite;
        $this->suiteicon = $this->get_suite_icon($suite);
        $this->glyph = $this->get_card_glyph($suite, $rank);
        $this->symbol = $this->suiteicon . $this->rank;
    }

    private function get_card_suite(int $suite): string
    {
        return match ($suite) {
            1  => 'clubs',
            2  => 'diamonds',
            3  => 'hearts',
            4  => 'spades',
        };
    }

    private function get_suite_icon(int $suite): string
    {
        return match ($suite) {
            1  => '♣',
            2  => '♦',
            3  => '♥',
            4  => '♠',
        };
    }

    private function get_card_rank(int $rank): string
    {
        return match ($rank) {
            1  => 'A',
            2  => '2',
            3  => '3',
            4  => '4',
            5  => '5',
            6  => '6',
            7  => '7',
            8  => '8',
            9  => '9',
            10 => '10',
            11 => 'J',
            12 => 'Q',
            13 => 'K',
        };
    }

    private function get_card_glyph(int $suite, int $rank): string
    {
        $card = match ($suite) {
            1  => 0x1F0D,
            2  => 0x1F0C,
            3  => 0x1F0B,
            4  => 0x1F0A,
        };

        $card = match ($rank) {
            12      => $card * 16 + 0xD,
            13      => $card * 16 + 0xE,
            default => $card * 16 + $rank
        };
        
        return mb_chr($card, 'UTF-8');
    }

    private function get_card_rankname(int $rank): string
    {
        return match ($rank) {
            1  => 'ace',
            2  => 'two',
            3  => 'three',
            4  => 'four',
            5  => 'five',
            6  => 'six',
            7  => 'seven',
            8  => 'eight',
            9  => 'nine',
            10 => 'ten',
            11 => 'jack',
            12 => 'queen',
            13 => 'king',
        };
    }



}

class Hand
{
    private array $hand;

    /**
     * Create new hand from the deck
     * @param Deck $deck 
     * @param int $cards 
     * @return void 
     */
    public function __construct(Deck $deck, int $cards)
    {
        $this->hand = $deck->deal($cards);
    }

    /**
     * Show a specific card from the hand or whole hand if $card = 0
     * @param int $card 
     * @param string $type
     * @return string 
     */
    public function show(int $card = 0, string $type = 'symbol'): string
    {
        if ($card == 0) {
            $string = '';
            foreach ($this->hand as $value) {
                if ($type == 'symbol') {
                    $string .= str_pad($value->symbol, 6, ' ');
                } else {
                    $string .= $value->$type . ' ';
                }
            }
            return $string;
        } else {
            return $this->hand[$card-1]->symbol;
        }
    }

    /**
     * Choose a specific card from the hand 
     * @param int $card 
     * @return Card|bool 
     */
    public function pick(int $card = 1): Card|bool
    {
        if ($card > 0 && $card <= (count($this->hand) + 1)) {
            $picked = $this->hand[$card-1];
            unset($this->hand[$card-1]);
            return $picked;
        } else {
            return false;
        }
    }

    /** 
     * Count cards in the hand
     * @return int  
     */
    public function count(): int
    {
        return count($this->hand);
    }

    /** 
     * Choose a random card from the hand 
     * @return Card 
     */
    public function rand(): Card
    {
        return $this->pick(1, count($this->hand));
    }

    
    /**
     * Callback comparison function for suits
     * @param Card $card1 
     * @param Card $card2 
     * @param array $suitorder 
     * @return int 
     */
    public function compare_suite(Card $card1, Card $card2, array $suitorder = DEFAULT_SUIT_ORDER):int
    {        
        return array_search($card1->suite, $suitorder) <=> array_search($card2->suite, $suitorder);
    }

    /**
     * Callback comparison function for ranks
     * @param Card $card1 
     * @param Card $card2 
     * @param array $cardsorder 
     * @return int 
     */
    public function compare_rank(Card $card1, Card $card2, array $cardsorder = DEFAULT_RANK_ORDER): int
    {
        return array_search($card1->rank, $cardsorder) <=> array_search($card2->rank, $cardsorder);
    }

    /**
     * Sort cards in the hand
     * @return void
     */
    public function sort(): void {
        usort($this->hand, 'Barabasz\Cards\Hand::compare_rank');
        usort($this->hand, 'Barabasz\Cards\Hand::compare_suite');
    }




}

class Deck
{
    private array $deck;

    public function __construct()
    {
        $this->deck = $this->make_deck();
    }

    private function make_deck(): array
    {
        $deck = [];
        for ($s = 1; $s < 5; $s++) { 
            for ($r = 1; $r < 14; $r++) { 
                $deck[$s][$r] = new Card($s, $r);
            }
        }
        return $deck;
    }

    public function deal(int $i = 1): array|bool
    {
        if (array_sum(array_map("count", $this->deck)) >= $i) {
            $hand = [];
            while (($a = $a ?? 1) <= $i) {
                $s = rand(1, 4);
                $r = rand(1, 13);
                
                if ($this->deck[$s][$r] ?? false) {
                    $hand[] = $this->deck[$s][$r];
                    unset($this->deck[$s][$r]);
                    $a++;
                }             
            }
            return $hand;
        } else {
            return false;
        }
    }

    public function show(): string
    {
        $string = '';
        foreach ($this->deck as $i) {
            foreach ($i as $j) {
                $string .= $j->symbol . ' ';
            }
            $string .=  PHP_EOL;
        }
        return $string . PHP_EOL;
    }

}
