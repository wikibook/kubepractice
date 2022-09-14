// k6 run stages.js

import http from 'k6/http';
import { check, sleep } from 'k6';

// ramp up, divide 3 duration
export const options = {
  stages: [
    { duration: '1m', target: 500 },
    { duration: '2m', target: 500 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  // const res = http.get('https://httpbin.org/');
  const res = http.get('http://172.17.29.80/');
  check(res, { 'status was 200': (r) => r.status == 200 });
  sleep(1);
}
