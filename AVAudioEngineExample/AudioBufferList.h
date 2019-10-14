//
//  AudioBufferList.h
//  AVAudioEngineExample
//
//  Created by Boris Dering on 07.10.19.
//  Copyright © 2019 Boris Dering. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

AVAudioPCMBuffer* AVAudioPCMBufferCreate(AVAudioFormat* format, AudioBufferList* bufferList, AVAudioFrameCount capacity);
