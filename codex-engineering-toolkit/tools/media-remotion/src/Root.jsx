import React from 'react';
import {Composition} from 'remotion';
import {EngineeringIntro} from './EngineeringIntro';

export const RemotionRoot = () => (
  <Composition
    id="EngineeringIntro"
    component={EngineeringIntro}
    durationInFrames={150}
    fps={30}
    width={1920}
    height={1080}
    defaultProps={{
      title: 'Yaroslav Engineering Toolkit',
      subtitle: 'Local, repeatable, verified',
    }}
  />
);
