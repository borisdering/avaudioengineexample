//
//  AudioBufferList.m
//  AVAudioEngineExample
//
//  Created by Boris Dering on 08.10.19.
//  Copyright © 2019 Boris Dering. All rights reserved.
//

#import "AudioBufferList.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <math.h>

AVAudioPCMBuffer* AVAudioPCMBufferCreate(AVAudioFormat* format, AudioBufferList* list, AVAudioFrameCount capacity) {
    
    AVAudioPCMBuffer *outBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:capacity];
    
    // usually we recevice a buffer list of 1!?! Why is it called list? :-P
    AudioBuffer *pBuffer = &list->mBuffers[0];
    
    // I'm not sure if I receive float or int array, can't tell..
    // but int 32 seems promising... float array values seems odd somehow...
    outBuffer.frameLength = pBuffer->mDataByteSize / sizeof(int);
    int *data = (int *)pBuffer->mData;
    
    memcpy(outBuffer.int32ChannelData[0], data, pBuffer->mDataByteSize);
    memcpy(outBuffer.int32ChannelData[1], data, pBuffer->mDataByteSize);
    
    return outBuffer;
}
