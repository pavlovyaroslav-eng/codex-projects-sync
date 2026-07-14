import React from 'react';
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

export const EngineeringIntro = ({title, subtitle}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame, fps, config: {damping: 18}});
  const opacity = interpolate(frame, [0, 15, 125, 149], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        alignItems: 'center',
        backgroundColor: '#07111f',
        color: '#f5f7fa',
        fontFamily: 'Arial, sans-serif',
        justifyContent: 'center',
        opacity,
      }}
    >
      <div
        style={{
          border: '2px solid #45b8ff',
          borderRadius: 28,
          padding: '64px 88px',
          textAlign: 'center',
          transform: 'scale(' + (0.9 + entrance * 0.1) + ')',
        }}
      >
        <div style={{fontSize: 72, fontWeight: 700}}>{title}</div>
        <div style={{color: '#8dd6ff', fontSize: 36, marginTop: 24}}>
          {subtitle}
        </div>
      </div>
    </AbsoluteFill>
  );
};
