import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class TokenBlacklistService implements OnModuleInit {
  private redis: Redis;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    this.redis = new Redis({
      host: this.configService.get('REDIS_HOST') || 'localhost',
      port: this.configService.get('REDIS_PORT') || 6379,
      password: this.configService.get('REDIS_PASSWORD') || undefined,
      db: 1, // Use separate database for blacklist
    });
  }

  /**
   * Add a token to the blacklist
   * @param token - The JWT token to blacklist
   * @param expiresIn - TTL in seconds (token's remaining lifetime)
   */
  async blacklistToken(token: string, expiresIn: number): Promise<void> {
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
    await this.redis.quit();
  }
}
