// Calculate Fibonacci Numbers
// Public Domain
// https://creativecommons.org/publicdomain/zero/1.0/

#include <stdio.h>
#include <ctype.h>
#include <gmp.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

int main(int argc, char *argv[])
{
    // Get User Input
    //if (argc != 2)
    //{
    //    fprintf(stderr, "Usage: %s <number>\n", argv[0]);
    //    return EXIT_FAILURE;
    //}
    //long count = strtol(argv[1], NULL, 10);
    
    // Inscript Input
    long count = 10000;
    
    // Setup GMP
    mpz_t a, b, p, q;
    mpz_init_set_ui(a, 1);
    mpz_init_set_ui(b, 0);
    mpz_init_set_ui(p, 0);
    mpz_init_set_ui(q, 1);
    mpz_t tmp;
    mpz_init(tmp);
    
    // Start timing
    const clock_t start_time = clock();
    
    while (count > 0) {
		if (count % 2 == 0) {
			mpz_mul(tmp, q, q);
			mpz_mul(q, q, p);
			mpz_mul_2exp(q, q, 1);
			mpz_add(q, q, tmp);
			mpz_mul(p, p, p);
			mpz_add(p, p, tmp);
			count /= 2;
		} else {
			mpz_mul(tmp, a, q);
			mpz_mul(a, a, p);
			mpz_addmul(a, b, q);
			mpz_add(a, a, tmp);
			mpz_mul(b, b, p);
			mpz_add(b, b, tmp);
			count -= 1;
		}
   	}
    
    // End timing
    const clock_t end_time = clock();
    
    if (end_time == (clock_t){-1})
    {
        fprintf(stderr, "Error end_time clock()\n");
        return EXIT_FAILURE;
    }
    
    mpz_out_str(stdout, 10, b);
    unsigned int digits = strlen(mpz_get_str(NULL, 10, b));
    printf("\n");
    
    // Cleanup
    mpz_clear(a);
    mpz_clear(b);
    mpz_clear(p);
    mpz_clear(q);
    mpz_clear(tmp);
    
    // Print time taken
    const double time_taken = ((double) (end_time - start_time)) / (double) CLOCKS_PER_SEC;
    if (printf("Calculation Time: %lf seconds\n", time_taken) < 0) 
        return EXIT_FAILURE;
    if (fflush(stdout) == EOF) 
        return EXIT_FAILURE;
    printf("Number of Digits: %u\n", digits);
	return EXIT_SUCCESS;
}
