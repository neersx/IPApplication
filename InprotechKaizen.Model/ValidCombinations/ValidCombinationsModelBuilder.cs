using InprotechKaizen.Model.Persistence;
using System.Data.Entity;

namespace InprotechKaizen.Model.ValidCombinations
{
    public class ValidCombinationsModelBuilder : IModelBuilder
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DateOfLaw>()
                        .HasKey(dol => new { dol.CountryId, dol.PropertyTypeId, dol.Date, dol.SequenceNo });

            modelBuilder.Entity<ValidProperty>().HasKey(vp => new { vp.CountryId, vp.PropertyTypeId});
            modelBuilder.Entity<ValidCategory>().HasKey(vc => new { vc.CountryId, vc.PropertyTypeId, vc.CaseTypeId, vc.CaseCategoryId });
            ConfigureValidSubType(modelBuilder);
            modelBuilder.Entity<ValidBasis>().HasKey(vb => new { vb.CountryId, vb.PropertyTypeId, vb.BasisId});
            modelBuilder.Entity<ValidBasisEx>().HasKey(vbe => new { vbe.CountryId, vbe.PropertyTypeId, vbe.CaseCategoryId, vbe.CaseTypeId, vbe.BasisId });
            modelBuilder.Entity<ValidStatus>()
                .HasKey(vs => new {vs.CountryId, vs.PropertyTypeId, vs.CaseTypeId, vs.StatusCode});
            modelBuilder.Entity<ValidChecklist>()
                .HasKey(vc => new { vc.CountryId, vc.PropertyTypeId, vc.CaseTypeId, vc.ChecklistType });
            modelBuilder.Entity<ValidRelationship>()
                .HasKey(vr => new { vr.CountryId, vr.PropertyTypeId, vr.RelationshipCode});

            modelBuilder.Entity<ValidBasisEx>()
                        .HasRequired(x => x.ValidBasis)
                        .WithMany()
                        .HasForeignKey(x => new {x.CountryId, x.PropertyTypeId, x.BasisId});
        }

        static void ConfigureValidSubType(DbModelBuilder modelBuilder)
        {
            var validSubType = modelBuilder.Entity<ValidSubType>();
            validSubType.Map(vs => vs.ToTable("VALIDSUBTYPE"));
            validSubType.HasKey(vs => new { vs.CountryId, vs.PropertyTypeId, vs.CaseTypeId, vs.CaseCategoryId, vs.SubtypeId});

            validSubType.HasRequired(vc => vc.ValidCategory)
                .WithMany()
                .HasForeignKey(vc => new { vc.CountryId, vc.PropertyTypeId, vc.CaseTypeId, vc.CaseCategoryId }); 
        }
    }
}
