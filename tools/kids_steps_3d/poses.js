const seat = { scene: 'wudu', pelvis: [0, 0.37, -0.06], chest: [0, 0.76, 0.05], lFoot: [0.1, 0.05, 0.27], rFoot: [-0.1, 0.05, 0.27], lKnee: [0.12, 0.6, 1], rKnee: [-0.12, 0.6, 1], cam: [2.6, 1.3, 0.6], look: [-0.02, 0.68, 0.18], zoom: 0.8, fov: 30, stoolY: 0.3 };
const stand = { scene: 'salah', zoom: 0.85, skirt: true, pelvis: [0, 0.66, 0], lFoot: [0.08, 0.045, 0.03], rFoot: [-0.08, 0.045, 0.03], cam: [2.4, 1.45, 2.8], look: [0, 0.72, 0.12], fov: 30 };
const SIT = (o) => ({ ...stand, skirt: false, pelvis: [0, 0.2, -0.08], chest: [0, 0.6, -0.04], lFoot: [0.07, 0.06, -0.12], rFoot: [-0.07, 0.11, -0.17], lKnee: [0.1, 0, 1], rKnee: [-0.1, 0, 1], lFootDir: [0, -0.1, -1], rFootDir: [0, -0.8, -0.4], lHand: [0.1, 0.28, 0.18], rHand: [-0.1, 0.28, 0.18], lElbow: { torso: [0.5, 0, -0.3] }, rElbow: { torso: [-0.5, 0, -0.3] }, cam: [1.9, 1.15, 2.2], look: [0, 0.42, 0.1], ...o });
const W = (o) => ({ ...seat, lElbow: { torso: [0.5, 0, -0.2] }, rElbow: { torso: [-0.5, 0, -0.2] }, ...o });
export const POSES = {
  'w-hands': { ...seat, lHand: [0.035, 0.46, 0.48], rHand: [-0.035, 0.46, 0.48], lElbow: { torso: [0.5, 0, -0.2] }, rElbow: { torso: [-0.5, 0, -0.2] }, water: [[0, 0.55, 0.53], [0, 0.47, 0.49]] },
  's-takbir': { ...stand, lHand: { head: [0.17, -0.03, 0.07] }, rHand: { head: [-0.17, -0.03, 0.07] }, lElbow: { torso: [0.6, 0.1, 0] }, rElbow: { torso: [-0.6, 0.1, 0] } },
  's-ruku': { ...stand, look: [-0.22, 0.48, 0.35], pelvis: [0, 0.64, -0.07], chest: [0, 0.66, 0.33], lHand: [0.09, 0.38, 0.05], rHand: [-0.09, 0.38, 0.05], lElbow: { torso: [0.4, 0, 0.3] }, rElbow: { torso: [-0.4, 0, 0.3] }, lFoot: [0.08, 0.045, -0.02], rFoot: [-0.08, 0.045, -0.02] },
  's-sujood': { ...stand, skirt: false, pelvis: [0, 0.36, 0.0], chest: [0, 0.27, 0.37], lHand: [0.15, 0.03, 0.52], rHand: [-0.15, 0.03, 0.52], lElbow: { torso: [0.5, 0.1, -0.3] }, rElbow: { torso: [-0.5, 0.1, -0.3] }, lFoot: [0.07, 0.07, -0.28], rFoot: [-0.07, 0.07, -0.28], lKnee: [0.07, 0, 1], rKnee: [-0.07, 0, 1], lFootDir: [0, -0.8, -0.5], rFootDir: [0, -0.8, -0.5] },

  'w-mouth': W({ lHand: [0.08, 0.42, 0.2], rHand: { head: [-0.03, -0.1, 0.2] }, rElbow: { torso: [-0.4, -0.2, 0.2] } }),
  'w-nose': W({ lHand: [0.08, 0.42, 0.2], rHand: { head: [-0.02, -0.04, 0.22] }, rElbow: { torso: [-0.4, -0.2, 0.2] } }),
  'w-face': W({ lHand: { head: [0.1, -0.03, 0.17] }, rHand: { head: [-0.1, -0.03, 0.17] }, lElbow: { torso: [0.3, -0.3, 0.3] }, rElbow: { torso: [-0.3, -0.3, 0.3] } }),
  'w-arms': W({ lHand: [0.02, 0.47, 0.48], rHand: [0.05, 0.52, 0.32], rElbow: { torso: [-0.5, 0.1, 0] }, water: [[0, 0.55, 0.53], [0.02, 0.5, 0.45]] }),
  'w-head': W({ lHand: { head: [0.07, 0.1, 0.02] }, rHand: { head: [-0.07, 0.1, 0.02] }, lElbow: { torso: [0.5, 0.6, 0.2] }, rElbow: { torso: [-0.5, 0.6, 0.2] } }),
  'w-ears': W({ lHand: { head: [0.2, 0.0, 0.0] }, rHand: { head: [-0.2, 0.0, 0.0] }, lElbow: { torso: [0.6, 0.0, 0.1] }, rElbow: { torso: [-0.6, 0.0, 0.1] } }),
  'w-feet': W({ chest: [0, 0.74, 0.14], rFoot: [-0.04, 0.3, 0.45], rKnee: [-0.3, 1.2, 0.6], rFootDir: [0, 0, 1], lHand: [0.0, 0.36, 0.48], rHand: [-0.09, 0.4, 0.42], water: [[0, 0.55, 0.53], [-0.03, 0.36, 0.5]] }),

  's-qiyam': { ...stand, lHand: { torso: [0.03, 0.27, 0.15] }, rHand: { torso: [-0.01, 0.29, 0.17] }, lElbow: { torso: [0.5, 0.1, -0.1] }, rElbow: { torso: [-0.5, 0.1, -0.1] } },
  's-qiyam2': { ...stand, cam: [1.0, 1.5, 3.6], look: [0, 0.62, 0.1], lHand: { torso: [0.03, 0.27, 0.15] }, rHand: { torso: [-0.01, 0.29, 0.17] }, lElbow: { torso: [0.5, 0.1, -0.1] }, rElbow: { torso: [-0.5, 0.1, -0.1] } },
  's-itidal': { ...stand, lHand: { head: [0.2, -0.17, 0.07] }, rHand: { head: [-0.2, -0.17, 0.07] }, lElbow: { torso: [0.6, -0.1, 0] }, rElbow: { torso: [-0.6, -0.1, 0] } },
  's-takbir2': { ...stand, cam: [1.0, 1.5, 3.6], look: [0, 0.62, 0.1], lHand: { head: [0.17, -0.03, 0.07] }, rHand: { head: [-0.17, -0.03, 0.07] }, lElbow: { torso: [0.6, 0.1, 0] }, rElbow: { torso: [-0.6, 0.1, 0] } },
  's-sujood2': { ...stand, cam: [-2.3, 1.2, 2.0], look: [0, 0.35, 0.2], skirt: false, pelvis: [0, 0.36, 0.0], chest: [0, 0.27, 0.37], lHand: [0.15, 0.03, 0.52], rHand: [-0.15, 0.03, 0.52], lElbow: { torso: [0.5, 0.1, -0.3] }, rElbow: { torso: [-0.5, 0.1, -0.3] }, lFoot: [0.07, 0.07, -0.28], rFoot: [-0.07, 0.07, -0.28], lKnee: [0.07, 0, 1], rKnee: [-0.07, 0, 1], lFootDir: [0, -0.8, -0.5], rFootDir: [0, -0.8, -0.5] },
  's-jalsa': SIT({}),
  's-tashahhud': SIT({ rHand: [-0.1, 0.29, 0.2], rPoint: true }),
  's-tawarruk': SIT({ pelvis: [0.06, 0.15, -0.06], chest: [0.03, 0.55, -0.03], lFoot: [-0.22, 0.04, 0.02], lFootDir: [-1, 0, 0.2], lKnee: [0.3, 0, 1], rHand: [-0.1, 0.29, 0.2], rPoint: true }),
  's-salam': SIT({ headYaw: -1.0, cam: [-1.7, 1.15, 2.4] }),
};
