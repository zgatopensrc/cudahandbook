/*
 *
 * eventRecord.cu
 *
 * Microbenchmark for throughput of event recording
 *
 * Build with: nvcc -I ../chLib <options> eventRecord.cu
 * Requires: No minimum SM requirement.
 *
 * Copyright (c) 2011-2014, Archaea Software, LLC.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions 
 * are met: 
 *
 * 1. Redistributions of source code must retain the above copyright 
 *    notice, this list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright 
 *    notice, this list of conditions and the following disclaimer in 
 *    the documentation and/or other materials provided with the 
 *    distribution. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include <stdio.h>

#include "chError.h"
#include "chTimer.h"

__global__
void
NullKernel()
{
}

template<bool bLaunch>
double
usPerLaunch( int cIterations, int cEvents )
{
    cudaError_t status;
    double microseconds, ret;
    cudaEvent_t *events = new cudaEvent_t[cIterations];
    chTimerTimestamp start, stop;

    if ( ! events ) goto Error;
    for ( int i = 0; i < cEvents; i++ ) {
        CUDART_CHECK( cudaEventCreateWithFlags(  &events[i], cudaEventBlockingSync ) );
    }

    chTimerGetTime( &start );
    for ( int i = 0; i < cIterations; i++ ) {
        if ( bLaunch ) NullKernel<<<1,1>>>();
        for ( int j = 0; j < cEvents; j++ ) {
            CUDART_CHECK( cudaEventRecord( events[j], NULL ) );
        }
    }
    CUDART_CHECK( cudaThreadSynchronize() );
    chTimerGetTime( &stop );

    microseconds = 1e6*chTimerElapsedTime( &start, &stop );
    if ( cEvents ) cIterations *= cEvents;
    ret = microseconds / (float) cIterations;

Error:
    delete[] events;
    return (status) ? 0.0 : ret;
}

int
main( int argc, char *argv[] )
{
    const int cIterations = 10000;
    printf( "Measuring asynchronous launch time...\n" ); fflush( stdout );

    printf( "#events\tus per event signaling\n" );
    for ( int cEvents = 0; cEvents < 5; cEvents += 1 ) {
        printf( "%d\t%.2f\n", cEvents*10, usPerLaunch<false>(cIterations, cEvents) );
    }
    printf( "Measuring asynchronous launch+event signaling...\n" ); fflush( stdout );
    for ( int cEvents = 0; cEvents < 5; cEvents += 1 ) {
        printf( "%d\t%.2f\n", cEvents*10, usPerLaunch<true>(cIterations, cEvents) );
    }

    return 0;
}

