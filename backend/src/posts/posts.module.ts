import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Post } from './entities/post.entity';
import { Comment } from './entities/comment.entity';
import { Like } from './entities/like.entity';
import { Follow } from './entities/follow.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Post, Comment, Like, Follow]),
  ],
  controllers: [],
  providers: [],
  exports: [],
})
export class PostsModule {}