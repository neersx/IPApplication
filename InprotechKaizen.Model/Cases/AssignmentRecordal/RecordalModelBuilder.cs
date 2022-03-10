using System;
using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Cases.AssignmentRecordal
{
    public class RecordalModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException($"modelBuilder");

            var rt = modelBuilder.Entity<RecordalType>();
            rt.HasOptional(_ => _.RecordEvent)
              .WithMany()
              .HasForeignKey(_ => _.RecordEventId);
            rt.HasOptional(_ => _.RequestEvent)
              .WithMany()
              .HasForeignKey(_ => _.RequestEventId);
            rt.HasOptional(_ => _.RequestAction)
              .WithMany()
              .HasForeignKey(_ => _.RequestActionId);
            rt.HasOptional(_ => _.RecordAction)
              .WithMany()
              .HasForeignKey(_ => _.RecordActionId);

            modelBuilder.Entity<Element>();
            var recStep = modelBuilder.Entity<RecordalStep>();
            recStep.HasRequired(rs => rs.RecordalType)
                   .WithMany()
                   .HasForeignKey(rs => rs.TypeId);

            var recElement = modelBuilder.Entity<RecordalElement>();
            recElement.HasRequired(rs => rs.RecordalType)
                      .WithMany()
                      .HasForeignKey(rs => rs.TypeId);
            recElement.HasRequired(rs => rs.Element)
                      .WithMany()
                      .HasForeignKey(rs => rs.ElementId);
            recElement.HasOptional(rs => rs.NameType)
                      .WithMany()
                      .HasForeignKey(rs => rs.NameTypeCode);

            var recStepElement = modelBuilder.Entity<RecordalStepElement>();
            recStepElement.HasRequired(rs => rs.Element)
                          .WithMany()
                          .HasForeignKey(rs => rs.ElementId);
            recStepElement.HasOptional(rs => rs.NameType)
                          .WithMany()
                          .HasForeignKey(rs => rs.NameTypeCode);

            var recAffectedCases = modelBuilder.Entity<RecordalAffectedCase>();
            recAffectedCases.HasRequired(rs => rs.Case)
                            .WithMany()
                            .HasForeignKey(rs => rs.CaseId);
            recAffectedCases.HasRequired(rs => rs.RecordalType)
                            .WithMany()
                            .HasForeignKey(rs => rs.RecordalTypeNo);
            recAffectedCases.HasOptional(rs => rs.Country)
                            .WithMany()
                            .HasForeignKey(rs => rs.CountryId);
            recAffectedCases.HasOptional(rs => rs.RelatedCase)
                            .WithMany()
                            .HasForeignKey(rs => rs.RelatedCaseId);
            recAffectedCases.HasOptional(rs => rs.Agent)
                            .WithMany()
                            .HasForeignKey(rs => rs.AgentId);
        }
    }
}
