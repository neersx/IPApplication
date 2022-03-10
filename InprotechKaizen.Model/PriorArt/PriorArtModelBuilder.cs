using System;
using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.PriorArt
{
    public class PriorArtModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if(modelBuilder == null) throw new ArgumentNullException("modelBuilder");

            var priorArt = modelBuilder.Entity<PriorArt>();

            priorArt.HasOptional(pa => pa.Country)
                    .WithMany()
                    .Map(c => c.MapKey("COUNTRYCODE"));

            priorArt.HasOptional(pa => pa.IssuingCountry)
                    .WithMany()
                    .Map(c => c.MapKey("ISSUINGCOUNTRY"));

            priorArt.HasMany(pa => pa.SourceDocuments)
                    .WithMany(pa => pa.CitedPriorArt)
                    .Map(m => m.ToTable("REPORTCITATIONS").MapLeftKey("CITEDPRIORARTID").MapRightKey("SEARCHREPORTID"));
        }
    }
}