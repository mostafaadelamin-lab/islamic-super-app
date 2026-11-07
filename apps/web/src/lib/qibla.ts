/** Live Qibla compass math (device heading from DeviceOrientation events). */

const FULL_TURN = 360;
const HALF_TURN = 180;
/** Within this many degrees of the Qibla the UI says the device is facing it. */
export const FACING_TOLERANCE = 5;

/** Normalises an angle to [0, 360). */
export function norm360(deg: number): number {
  return ((deg % FULL_TURN) + FULL_TURN) % FULL_TURN;
}

/** Signed smallest difference target − current in (−180, 180]. */
export function angleDiff(target: number, current: number): number {
  const d = norm360(target - current);
  return d > HALF_TURN ? d - FULL_TURN : d;
}

export interface OrientationLike {
  alpha: number | null;
  absolute?: boolean;
  /** iOS Safari: degrees clockwise from magnetic north. */
  webkitCompassHeading?: number;
}

/**
 * Compass heading (degrees clockwise from north) of the top of the device, or null when the event does not
 * carry an absolute (north-referenced) orientation. `screenAngle` is screen.orientation.angle.
 */
export function headingFromEvent(e: OrientationLike, screenAngle = 0): number | null {
  if (typeof e.webkitCompassHeading === "number" && Number.isFinite(e.webkitCompassHeading)) {
    return norm360(e.webkitCompassHeading + screenAngle);
  }
  if (e.absolute === true && typeof e.alpha === "number" && Number.isFinite(e.alpha)) {
    // alpha grows counter-clockwise; the heading grows clockwise.
    return norm360(FULL_TURN - e.alpha + screenAngle);
  }
  return null;
}

/** Rotation of the Qibla needle on screen: the bearing seen from the current device heading. */
export function needleRotation(bearing: number, heading: number | null): number {
  return heading === null ? norm360(bearing) : norm360(bearing - heading);
}

export function isFacing(bearing: number, heading: number | null, tolerance = FACING_TOLERANCE): boolean {
  return heading !== null && Math.abs(angleDiff(bearing, heading)) <= tolerance;
}

/** Whether the browser needs an explicit permission request (iOS 13+). */
export function needsPermission(ctor: unknown): boolean {
  return (
    typeof ctor === "function" &&
    typeof (ctor as { requestPermission?: unknown }).requestPermission === "function"
  );
}
