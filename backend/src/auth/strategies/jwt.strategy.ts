import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UsersService } from '../../users/users.service';
import { TokenBlacklistService } from '../token-blacklist.service';
import { Request } from 'express';

export interface JwtPayload {
  sub: string; // user id
  username: string;
  email: string;
  userType: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private usersService: UsersService,
    private tokenBlacklistService: TokenBlacklistService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('JWT_SECRET'),
      passReqToCallback: true, // Pass request to validate method
    });
  }

  async validate(req: Request, payload: JwtPayload) {
    // Extract token from header
    const token = ExtractJwt.fromAuthHeaderAsBearerToken()(req);

    // Check if token is blacklisted
    if (token && (await this.tokenBlacklistService.isBlacklisted(token))) {
      throw new UnauthorizedException('Token has been revoked');
    }

    const user = await this.usersService.findById(payload.sub);

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Return user object that will be attached to request
    return {
      id: user.id,
      username: user.username,
      email: user.email,
      userType: user.userType,
      displayName: user.displayName,
      profileImageUrl: user.profileImageUrl,
      isVerified: user.isVerified,
      onboardingCompleted: user.onboardingCompleted,
    };
  }
}