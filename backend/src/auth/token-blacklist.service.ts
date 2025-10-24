import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class TokenBlacklistService implements OnModuleInit {
  private redis: Redis | null = null;
  private readonly logger = new Logger(TokenBlacklistService.name);

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    const redisHost = this.configService.get('REDIS_HOST');

    // Only connect to Redis if REDIS_HOST is configured
    if (!redisHost) {
      this.logger.warn('Redis not configured - token blacklist will be disabled');
      return;
    }

    try {
      this.redis = new Redis({
        host: redisHost,
        port: this.configService.get('REDIS_PORT') || 6379,
        password: this.configService.get('REDIS_PASSWORD') || undefined,
        db: 1, // Use separate database for blacklist
        retryStrategy: () => null, // Disable retries
        maxRetriesPerRequest: 0,
        lazyConnect: true, // Don't connect immediately
      });

      // Add error handler before connecting
      this.redis.on('error', (error) => {
        this.logger.error('Redis error:', error.message);
      });

      // Try to connect
      await this.redis.connect();
      this.logger.log('Redis connection established for token blacklist');
    } catch (error) {
      this.logger.error('Failed to connect to Redis - token blacklist will be disabled', error);
      if (this.redis) {
        this.redis.disconnect();
      }
      this.redis = null;
    }
  }

  /**
   * Add a token to the blacklist
   * @param token - The JWT token to blacklist
   * @param expiresIn - TTL in seconds (token's remaining lifetime)
   */
  async blacklistToken(token: string, expiresIn: number): Promise<void> {
    if (!this.redis) {
      this.logger.warn('Cannot blacklist token - Redis not available');
      return;
    }

    const key = `blacklist:${token}`;
    // Store with TTL so Redis automatically removes after expiration
    await this.redis.setex(key, expiresIn, '1');
  }

  /**
   * Check if a token is blacklisted
   * @param token - The JWT token to check
   * @returns true if token is blacklisted, false otherwise
   */
  async isBlacklisted(token: string): Promise<boolean> {
    if (!this.redis) {
      // When Redis isn't available, tokens can't be blacklisted
      return false;
    }

    const key = `blacklist:${token}`;
    const result = await this.redis.get(key);
    return result !== null;
  }

  /**
   * Calculate remaining TTL for a JWT token
   * @param exp - Token expiration timestamp (from JWT payload)
   * @returns TTL in seconds
   */
  calculateTTL(exp: number): number {
    const now = Math.floor(Date.now() / 1000);
    const ttl = exp - now;
    return ttl > 0 ? ttl : 0;
  }

  async onModuleDestroy() {
    if (this.redis) {
      await this.redis.quit();
    }
  }
}
