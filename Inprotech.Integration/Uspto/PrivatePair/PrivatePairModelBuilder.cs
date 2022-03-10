using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair.Certificates;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using System;
using System.Data.Entity;

namespace Inprotech.Integration.Uspto.PrivatePair
{
    public class PrivatePairModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException("modelBuilder");
            modelBuilder.Entity<Certificate>();
            modelBuilder.Entity<Sponsorship>();
        }
    }
}