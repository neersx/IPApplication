using System;
using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Storage
{
    public class StorageModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException("modelBuilder");

            modelBuilder.Entity<FileStore>();
            modelBuilder.Entity<TempStorage>();
            modelBuilder.Entity<FileMetadata>();
            modelBuilder.Entity<MessageStore>();
            modelBuilder.Entity<MessageStoreFileQueue>();
        }
    }
}