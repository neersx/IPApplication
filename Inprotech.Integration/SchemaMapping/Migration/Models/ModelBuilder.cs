using System;
using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.SchemaMapping.Migration.Models
{
    public class ModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if(modelBuilder == null) throw new ArgumentNullException("modelBuilder");

            modelBuilder.Entity<ObsoleteSchemaFile>()
                        .HasOptional(_=>_.ObsoleteSchemaPackage)
                        .WithMany()
                        .HasForeignKey(_=>_.SchemaPackageId);

            modelBuilder.Entity<ObsoleteSchemaMapping>()
                        .HasRequired(_ => _.ObsoleteSchemaPackage)
                        .WithMany()
                        .HasForeignKey(_ => _.SchemaPackageId);
            }
    }
}