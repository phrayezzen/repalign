import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Post } from './post.entity';

export enum MediaType {
  IMAGE = 'image',
  VIDEO = 'video',
  DOCUMENT = 'document',
  AUDIO = 'audio',
}

@Entity('media')
@Index(['uploadedBy'])
@Index(['associatedPostId'])
@Index(['mediaType'])
@Index(['createdAt'])
export class Media {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  url: string;

  @Column({
    type: 'enum',
    enum: MediaType,
    name: 'media_type',
  })
  mediaType: MediaType;

  @Column({ name: 'mime_type' })
  mimeType: string;

  @Column({ name: 'file_size' })
  fileSize: number; // in bytes

  @Column({ name: 'original_filename', nullable: true })
  originalFilename: string;

  @Column({ nullable: true })
  alt: string; // Alt text for accessibility

  @Column({ nullable: true })
  caption: string;

  @Column({ name: 'uploaded_by' })
  uploadedBy: string;

  @Column({ name: 'associated_post_id', nullable: true })
  associatedPostId: string;

  @Column({ name: 'width', nullable: true })
  width: number; // For images/videos

  @Column({ name: 'height', nullable: true })
  height: number; // For images/videos

  @Column({ name: 'duration', nullable: true })
  duration: number; // For videos/audio in seconds

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Relationships
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'uploaded_by' })
  uploader: User;

  @ManyToOne(() => Post, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'associated_post_id' })
  associatedPost: Post;

  // Helper methods
  get isImage(): boolean {
    return this.mediaType === MediaType.IMAGE;
  }

  get isVideo(): boolean {
    return this.mediaType === MediaType.VIDEO;
  }

  get isDocument(): boolean {
    return this.mediaType === MediaType.DOCUMENT;
  }

  get isAudio(): boolean {
    return this.mediaType === MediaType.AUDIO;
  }

  get fileSizeFormatted(): string {
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = this.fileSize;
    let unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return `${size.toFixed(1)} ${units[unitIndex]}`;
  }

  get aspectRatio(): number | null {
    if (!this.width || !this.height) return null;
    return this.width / this.height;
  }

  get durationFormatted(): string | null {
    if (!this.duration) return null;

    const hours = Math.floor(this.duration / 3600);
    const minutes = Math.floor((this.duration % 3600) / 60);
    const seconds = Math.floor(this.duration % 60);

    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  // Static helper methods
  static getMediaTypeFromMimeType(mimeType: string): MediaType {
    if (mimeType.startsWith('image/')) return MediaType.IMAGE;
    if (mimeType.startsWith('video/')) return MediaType.VIDEO;
    if (mimeType.startsWith('audio/')) return MediaType.AUDIO;
    return MediaType.DOCUMENT;
  }

  static isValidImageMimeType(mimeType: string): boolean {
    const validTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/svg+xml',
    ];
    return validTypes.includes(mimeType.toLowerCase());
  }

  static isValidVideoMimeType(mimeType: string): boolean {
    const validTypes = [
      'video/mp4',
      'video/mpeg',
      'video/quicktime',
      'video/webm',
      'video/ogg',
    ];
    return validTypes.includes(mimeType.toLowerCase());
  }
}