using System;
using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.SchemaMappings
{
    public class ModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException(nameof(modelBuilder));

            modelBuilder.Entity<SchemaFile>()
                        .HasOptional(_ => _.SchemaPackage)
                        .WithMany()
                        .HasForeignKey(_ => _.SchemaPackageId);

            modelBuilder.Entity<SchemaMapping>()
                        .HasRequired(_ => _.SchemaPackage)
                        .WithMany()
                        .HasForeignKey(_ => _.SchemaPackageId);

            modelBuilder.Entity<SchemaPackage>();
        }
    }
}