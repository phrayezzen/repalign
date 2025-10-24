import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Post } from './entities/post.entity';
import { Comment } from './entities/comment.entity';
import { Like } from './entities/like.entity';

@Injectable()
export class PostsService {
  constructor(
    @InjectRepository(Post)
    private postRepository: Repository<Post>,
    @InjectRepository(Comment)
    private commentRepository: Repository<Comment>,
    @InjectRepository(Like)
    private likeRepository: Repository<Like>,
  ) {}

  async getPostById(id: string): Promise<Post> {
    const post = await this.postRepository.findOne({
      where: { id },
      relations: ['author', 'comments', 'comments.author', 'likes'],
    });

    if (!post) {
      throw new NotFoundException(`Post with ID ${id} not found`);
    }

    return post;
  }

  async getPostComments(postId: string): Promise<Comment[]> {
    return this.commentRepository.find({
      where: { postId },
      relations: ['author'],
      order: { createdAt: 'DESC' },
    });
  }

  async createComment(postId: string, userId: string, content: string): Promise<Comment> {
    // Verify post exists
    const post = await this.postRepository.findOne({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException(`Post with ID ${postId} not found`);
    }

    const comment = this.commentRepository.create({
      postId,
      authorId: userId,
      content,
    } as any);

    const savedComment = await this.commentRepository.save(comment);

    // Increment comment count on post
    await post.incrementCommentCount();
    await this.postRepository.save(post);

    // Return comment with author relation
    return this.commentRepository.findOne({
      where: { id: (savedComment as any).id },
      relations: ['author'],
    });
  }

  async likePost(postId: string, userId: string): Promise<void> {
    // Check if already liked
    const existingLike = await this.likeRepository.findOne({
      where: { postId, userId },
    });

    if (existingLike) {
      return; // Already liked
    }

    // Create like
    const like = this.likeRepository.create({
      postId,
      userId,
    });

    await this.likeRepository.save(like);

    // Increment like count on post
    const post = await this.postRepository.findOne({ where: { id: postId } });
    if (post) {
      await post.incrementLikeCount();
      await this.postRepository.save(post);
    }
  }

  async unlikePost(postId: string, userId: string): Promise<void> {
    const like = await this.likeRepository.findOne({
      where: { postId, userId },
    });

    if (like) {
      await this.likeRepository.remove(like);

      // Decrement like count on post
      const post = await this.postRepository.findOne({ where: { id: postId } });
      if (post && post.likeCount > 0) {
        await post.decrementLikeCount();
        await this.postRepository.save(post);
      }
    }
  }

  async likeComment(commentId: string, userId: string): Promise<void> {
    // Check if already liked
    const existingLike = await this.likeRepository.findOne({
      where: { commentId, userId },
    });

    if (existingLike) {
      return; // Already liked
    }

    // Create like
    const like = this.likeRepository.create({
      commentId,
      userId,
    });

    await this.likeRepository.save(like);

    // Increment like count on comment
    const comment = await this.commentRepository.findOne({ where: { id: commentId } });
    if (comment) {
      await comment.incrementLikeCount();
      await this.commentRepository.save(comment);
    }
  }

  async unlikeComment(commentId: string, userId: string): Promise<void> {
    const like = await this.likeRepository.findOne({
      where: { commentId, userId },
    });

    if (like) {
      await this.likeRepository.remove(like);

      // Decrement like count on comment
      const comment = await this.commentRepository.findOne({ where: { id: commentId } });
      if (comment && comment.likeCount > 0) {
        await comment.decrementLikeCount();
        await this.commentRepository.save(comment);
      }
    }
  }

  async isPostLikedByUser(postId: string, userId: string): Promise<boolean> {
    const like = await this.likeRepository.findOne({
      where: { postId, userId },
    });
    return !!like;
  }

  async isCommentLikedByUser(commentId: string, userId: string): Promise<boolean> {
    const like = await this.likeRepository.findOne({
      where: { commentId, userId },
    });
    return !!like;
  }
}