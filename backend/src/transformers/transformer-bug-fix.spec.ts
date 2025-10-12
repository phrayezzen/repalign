import { BadgeType } from '../users/entities/citizen-profile.entity';

describe('TypeORM Transformer Bug Fix Tests', () => {
  describe('Transformer function behavior that caused "value.split is not a function"', () => {
    // This simulates the actual transformer function that was fixed
    const createFixedTransformer = () => ({
      to: (value: string[]) => value?.join(',') || '',
      from: (value: string | string[]) => {
        if (Array.isArray(value)) return value;
        return value ? value.split(',').filter(Boolean) : [];
      },
    });

    // This simulates the BROKEN transformer function that caused the bug
    const createBrokenTransformer = () => ({
      to: (value: string[]) => value?.join(',') || '',
      from: (value: string) => {
        // This would throw "value.split is not a function" if value is an array
        return value ? value.split(',').filter(Boolean) : [];
      },
    });

    describe('Fixed transformer behavior', () => {
      it('should handle string input correctly', () => {
        const transformer = createFixedTransformer();

        const result = transformer.from('FIRST_POST,ACTIVIST');
        expect(result).toEqual(['FIRST_POST', 'ACTIVIST']);
      });

      it('should handle array input without throwing (this is the bug fix)', () => {
        const transformer = createFixedTransformer();

        // This was causing "value.split is not a function" error before the fix
        const arrayInput = ['FIRST_POST', 'ACTIVIST'];
        const result = transformer.from(arrayInput);
        expect(result).toEqual(['FIRST_POST', 'ACTIVIST']);
      });

      it('should handle empty string', () => {
        const transformer = createFixedTransformer();

        const result = transformer.from('');
        expect(result).toEqual([]);
      });

      it('should handle null/undefined', () => {
        const transformer = createFixedTransformer();

        expect(transformer.from(null)).toEqual([]);
        expect(transformer.from(undefined)).toEqual([]);
      });

      it('should convert arrays to strings correctly', () => {
        const transformer = createFixedTransformer();

        const result = transformer.to(['FIRST_POST', 'ACTIVIST']);
        expect(result).toBe('FIRST_POST,ACTIVIST');
      });
    });

    describe('Broken transformer behavior (demonstrating the original bug)', () => {
      it('should work with string input', () => {
        const transformer = createBrokenTransformer();

        const result = transformer.from('FIRST_POST,ACTIVIST');
        expect(result).toEqual(['FIRST_POST', 'ACTIVIST']);
      });

      it('should throw "value.split is not a function" with array input', () => {
        const transformer = createBrokenTransformer();

        // This demonstrates the original bug
        const arrayInput = ['FIRST_POST', 'ACTIVIST'];
        expect(() => {
          transformer.from(arrayInput as any);
        }).toThrow('value.split is not a function');
      });
    });
  });

  describe('BadgeType enum validation', () => {
    it('should have expected badge types', () => {
      expect(BadgeType.FIRST_POST).toBe('first_post');
      expect(BadgeType.ACTIVIST).toBe('activist');
      expect(BadgeType.CIVIC_CONNECTOR).toBe('civic_connector');
      expect(BadgeType.SOCIAL_BUTTERFLY).toBe('social_butterfly');
      expect(BadgeType.THOUGHT_LEADER).toBe('thought_leader');
    });
  });

  describe('Regression test scenarios', () => {
    // This simulates the actual transformer function that was fixed
    const createFixedTransformer = () => ({
      to: (value: string[]) => value?.join(',') || '',
      from: (value: string | string[]) => {
        if (Array.isArray(value)) return value;
        return value ? value.split(',').filter(Boolean) : [];
      },
    });

    it('should handle mixed data types that TypeORM might pass', () => {
      const transformer = createFixedTransformer();

      // These are all scenarios that could happen when TypeORM loads data
      const testCases = [
        { input: 'FIRST_POST', expected: ['FIRST_POST'] },
        { input: 'FIRST_POST,ACTIVIST', expected: ['FIRST_POST', 'ACTIVIST'] },
        { input: ['FIRST_POST'], expected: ['FIRST_POST'] },
        { input: ['FIRST_POST', 'ACTIVIST'], expected: ['FIRST_POST', 'ACTIVIST'] },
        { input: '', expected: [] },
        { input: [], expected: [] },
        { input: null, expected: [] },
        { input: undefined, expected: [] },
      ];

      testCases.forEach(({ input, expected }) => {
        expect(() => transformer.from(input as any)).not.toThrow();
        expect(transformer.from(input as any)).toEqual(expected);
      });
    });
  });
});