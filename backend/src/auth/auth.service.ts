import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { User, UserType } from '../users/entities/user.entity';
import { JwtPayload } from './strategies/jwt.strategy';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(registerDto: RegisterDto): Promise<AuthResponseDto> {
    const { username, email, password, ...userData } = registerDto;

    // Check if user already exists
    const existingUser = await this.usersService.findByUsernameOrEmail(username, email);
    if (existingUser) {
      throw new ConflictException('Username or email already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create user
    const user = await this.usersService.create({
      username,
      email,
      password: hashedPassword,
      ...userData,
    });

    // Create profile based on user type
    if (user.userType === UserType.CITIZEN) {
      await this.usersService.createCitizenProfile(user.id);
    }
    // Note: Legislator profiles are created via Congress sync, not registration

    // Generate tokens
    const tokens = await this.generateTokens(user);

    return {
      ...tokens,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        displayName: user.displayName,
        userType: user.userType,
        profileImageUrl: user.profileImageUrl,
        isVerified: user.isVerified,
      },
    };
  }

  async login(user: User): Promise<AuthResponseDto> {
    const tokens = await this.generateTokens(user);

    return {
      ...tokens,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        displayName: user.displayName,
        userType: user.userType,
        profileImageUrl: user.profileImageUrl,
        isVerified: user.isVerified,
      },
    };
  }

  async validateUser(usernameOrEmail: string, password: string): Promise<User | null> {
    const user = await this.usersService.findByUsernameOrEmail(usernameOrEmail);

    if (!user) {
      return null;
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return null;
    }

    // Update last active
    await this.usersService.updateLastActive(user.id);

    return user;
  }

  async refreshTokens(refreshToken: string): Promise<AuthResponseDto> {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
      });

      const user = await this.usersService.findById(payload.sub);

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      const tokens = await this.generateTokens(user);

      return {
        ...tokens,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          displayName: user.displayName,
          userType: user.userType,
          profileImageUrl: user.profileImageUrl,
          isVerified: user.isVerified,
        },
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  private async generateTokens(user: User): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
  }> {
    const payload: JwtPayload = {
      sub: user.id,
      username: user.username,
      email: user.email,
      userType: user.userType,
    };

    const accessTokenExpiresIn = this.parseJwtExpiration(
      this.configService.get('JWT_EXPIRATION_TIME') || '15m',
    );

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_SECRET'),
        expiresIn: this.configService.get('JWT_EXPIRATION_TIME') || '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get('JWT_REFRESH_EXPIRATION_TIME') || '7d',
      }),
    ]);

    return {
      accessToken,
      refreshToken,
      expiresIn: accessTokenExpiresIn,
    };
  }

  private parseJwtExpiration(expiration: string): number {
    const unit = expiration.slice(-1);
    const value = parseInt(expiration.slice(0, -1));

    switch (unit) {
      case 's':
        return value;
      case 'm':
        return value * 60;
      case 'h':
        return value * 60 * 60;
      case 'd':
        return value * 60 * 60 * 24;
      default:
        return 900; // 15 minutes default
    }
  }
}