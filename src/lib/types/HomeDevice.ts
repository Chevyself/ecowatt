
export interface HomeDevice {
  /** Power rating in watts */
  powerRating: number;
  /** name */
  name: string;
  /** fa icon, must be compatible with solid (represents turned on) and regular (represents turned off) */
  icon: string;
  /** true if the device is currently on */
  isOn: boolean;
}

export function getKwS(device: HomeDevice): number {
  return device.powerRating / 1000;
}

// Home devices
const TV: HomeDevice = {
  powerRating: 100,
  name: 'TV',
  icon: 'tv',
  isOn: false
}

const Fridge: HomeDevice = {
  powerRating: 200,
  name: 'Fridge',
  icon: 'fridge',
  isOn: false
}

const Laptop: HomeDevice = {
  powerRating: 50,
  name: 'Laptop',
  icon: 'laptop',
  isOn: false
}

const Microwave: HomeDevice = {
  powerRating: 1500,
  name: 'Microwave',
  icon: 'microwave',
  isOn: false
}

const WashingMachine: HomeDevice = {
  powerRating: 1000,
  name: 'Washing Machine',
  icon: 'washing-machine',
  isOn: false
}

const Bulb: HomeDevice = {
  powerRating: 60,
  name: 'Bulb',
  icon: 'lightbulb',
  isOn: false
}

// All devices

export const devices = [
  TV,
  Laptop,
  Bulb,
]
