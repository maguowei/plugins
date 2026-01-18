import { useState, useCallback } from 'react';

interface UseCounterOptions {
  initialValue?: number;
  min?: number;
  max?: number;
  step?: number;
}

export function useCounter(options: UseCounterOptions = {}) {
  const { initialValue = 0, min = -Infinity, max = Infinity, step = 1 } = options;

  const [count, setCount] = useState(initialValue);

  const increment = useCallback(() => {
    setCount((c) => Math.min(c + step, max));
  }, [step, max]);

  const decrement = useCallback(() => {
    setCount((c) => Math.max(c - step, min));
  }, [step, min]);

  const reset = useCallback(() => {
    setCount(initialValue);
  }, [initialValue]);

  const set = useCallback(
    (value: number) => {
      setCount(Math.min(Math.max(value, min), max));
    },
    [min, max]
  );

  return { count, increment, decrement, reset, set };
}
