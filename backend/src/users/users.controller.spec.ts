import { Test, TestingModule } from '@nestjs/testing';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

describe('UsersController', () => {
  let controller: UsersController;
  let usersService: UsersService;

  const mockUsersService = {
    followUser: jest.fn(),
    unfollowUser: jest.fn(),
    isFollowing: jest.fn(),
    getFollowerCount: jest.fn(),
  };

  const mockUser = { id: 'user-123' };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<UsersController>(UsersController);
    usersService = module.get<UsersService>(UsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('followUser', () => {
    it('should follow a user successfully', async () => {
      const targetUserId = 'target-user-123';
      const mockResult = { success: true, message: 'User followed successfully' };

      mockUsersService.followUser.mockResolvedValue(mockResult);

      const result = await controller.followUser(targetUserId, mockUser);

      expect(usersService.followUser).toHaveBeenCalledWith('user-123', 'target-user-123');
      expect(result).toEqual(mockResult);
    });

    it('should handle follow user errors', async () => {
      const targetUserId = 'target-user-123';
      const error = new Error('User not found');

      mockUsersService.followUser.mockRejectedValue(error);

      await expect(controller.followUser(targetUserId, mockUser)).rejects.toThrow('User not found');
    });
  });

  describe('unfollowUser', () => {
    it('should unfollow a user successfully', async () => {
      const targetUserId = 'target-user-123';
      const mockResult = { success: true, message: 'User unfollowed successfully' };

      mockUsersService.unfollowUser.mockResolvedValue(mockResult);

      const result = await controller.unfollowUser(targetUserId, mockUser);

      expect(usersService.unfollowUser).toHaveBeenCalledWith('user-123', 'target-user-123');
      expect(result).toEqual(mockResult);
    });

    it('should handle unfollow user errors', async () => {
      const targetUserId = 'target-user-123';
      const error = new Error('User not found');

      mockUsersService.unfollowUser.mockRejectedValue(error);

      await expect(controller.unfollowUser(targetUserId, mockUser)).rejects.toThrow('User not found');
    });
  });

  describe('getFollowerCount', () => {
    it('should return follower count', async () => {
      const userId = 'user-123';
      const mockResult = { count: 150 };

      mockUsersService.getFollowerCount.mockResolvedValue(mockResult);

      const result = await controller.getFollowerCount(userId);

      expect(usersService.getFollowerCount).toHaveBeenCalledWith('user-123');
      expect(result).toEqual(mockResult);
    });
  });

  describe('isFollowing', () => {
    it('should check if user is following another user', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-user-123';
      const mockResult = { isFollowing: true };

      mockUsersService.isFollowing.mockResolvedValue(mockResult);

      const result = await controller.isFollowing(userId, targetUserId);

      expect(usersService.isFollowing).toHaveBeenCalledWith('user-123', 'target-user-123');
      expect(result).toEqual(mockResult);
    });

    it('should return false when user is not following', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-user-123';
      const mockResult = { isFollowing: false };

      mockUsersService.isFollowing.mockResolvedValue(mockResult);

      const result = await controller.isFollowing(userId, targetUserId);

      expect(usersService.isFollowing).toHaveBeenCalledWith('user-123', 'target-user-123');
      expect(result).toEqual(mockResult);
    });
  });
});