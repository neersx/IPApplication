using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EventControlMaintenance
{
    public class NameTypeMapMaintenanceFacts
    {
        public class ValidateMethod
        {
            [Fact]
            public void ReturnsErrorWhenMissingMandatoryFields()
            {
                var f = new NameTypeMapMaintenanceFixture();
                var model = new WorkflowEventControlSaveModel();
                model.NameTypeMapDelta = new Delta<NameTypeMapSaveModel>
                {
                    Added = new List<NameTypeMapSaveModel> {new NameTypeMapSaveModel {ApplicableNameTypeKey = "A", SubstituteNameTypeKey = "B"}},
                    Updated = new List<NameTypeMapSaveModel> {new NameTypeMapSaveModel {ApplicableNameTypeKey = "B", SubstituteNameTypeKey = "C"}}
                };
                var result = f.Subject.Validate(model);
                Assert.Empty(result);

                model.NameTypeMapDelta.Added.First().ApplicableNameTypeKey = null;
                result = f.Subject.Validate(model);
                Assert.Single(result);

                model.NameTypeMapDelta.Added.First().ApplicableNameTypeKey = "A";
                model.NameTypeMapDelta.Added.First().SubstituteNameTypeKey = null;
                result = f.Subject.Validate(model);
                Assert.Single(result);
            }
        }

        public class ApplyChangesMethod
        {
            [Fact]
            public void AddsAddedRows()
            {
                var f = new NameTypeMapMaintenanceFixture();
                var model = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var nameTypeMap = new NameTypeMapSaveModel();
                nameTypeMap.CopyFrom(new NameTypeMapBuilder().Build());

                model.NameTypeMapDelta = new Delta<NameTypeMapSaveModel>
                {
                    Added = new List<NameTypeMapSaveModel> {nameTypeMap}
                };
                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<NameTypeMapSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<NameTypeMapSaveModel, int>>(), Arg.Any<Func<NameTypeMapSaveModel, int>>())
                 .ReturnsForAnyArgs(model.NameTypeMapDelta);

                var validEvent = new ValidEventBuilder().Build();
                f.Subject.ApplyChanges(validEvent, model, fieldsToUpdate);

                Assert.Equal(1, validEvent.NameTypeMaps.Count);
                var added = validEvent.NameTypeMaps.First();
                Assert.Equal(nameTypeMap.ApplicableNameTypeKey, added.ApplicableNameTypeKey);
                Assert.Equal(nameTypeMap.SubstituteNameTypeKey, added.SubstituteNameTypeKey);
                Assert.Equal(nameTypeMap.MustExist, added.MustExist);
            }

            [Fact]
            public void DeletesDeletedRows()
            {
                var f = new NameTypeMapMaintenanceFixture();
                var model = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var nameTypeMap = new NameTypeMapSaveModel();
                nameTypeMap.CopyFrom(new NameTypeMapBuilder().Build());
                nameTypeMap.OriginalHashKey = nameTypeMap.HashKey();

                var validEvent = new ValidEventBuilder().Build();
                var existingNameTypeMap = new NameTypeMap();
                existingNameTypeMap.CopyFrom(nameTypeMap);
                validEvent.NameTypeMaps.Add(existingNameTypeMap);

                model.OriginatingCriteriaId = validEvent.CriteriaId;

                model.NameTypeMapDelta = new Delta<NameTypeMapSaveModel>
                {
                    Deleted = new List<NameTypeMapSaveModel> {nameTypeMap}
                };
                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<NameTypeMapSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<NameTypeMapSaveModel, int>>(), Arg.Any<Func<NameTypeMapSaveModel, int>>())
                 .ReturnsForAnyArgs(model.NameTypeMapDelta);

                f.Subject.ApplyChanges(validEvent, model, fieldsToUpdate);

                Assert.Equal(0, validEvent.NameTypeMaps.Count);
            }

            [Fact]
            public void UpdatesUpdatedRows()
            {
                var f = new NameTypeMapMaintenanceFixture();
                var model = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var nameTypeMap = new NameTypeMapSaveModel();
                nameTypeMap.CopyFrom(new NameTypeMapBuilder().Build());
                nameTypeMap.OriginalHashKey = nameTypeMap.HashKey();

                var validEvent = new ValidEventBuilder().Build();
                var existingNameTypeMap = new NameTypeMap();
                existingNameTypeMap.CopyFrom(nameTypeMap);
                validEvent.NameTypeMaps.Add(existingNameTypeMap);

                model.OriginatingCriteriaId = validEvent.CriteriaId;

                // update it
                nameTypeMap.SubstituteNameTypeKey = Fixture.String();

                model.NameTypeMapDelta = new Delta<NameTypeMapSaveModel>
                {
                    Updated = new List<NameTypeMapSaveModel> {nameTypeMap}
                };
                f.WorkflowEventInheritanceService.GetDelta(Arg.Any<Delta<NameTypeMapSaveModel>>(), Arg.Any<Delta<int>>(), Arg.Any<Func<NameTypeMapSaveModel, int>>(), Arg.Any<Func<NameTypeMapSaveModel, int>>())
                 .ReturnsForAnyArgs(model.NameTypeMapDelta);

                f.Subject.ApplyChanges(validEvent, model, fieldsToUpdate);

                Assert.Equal(1, validEvent.NameTypeMaps.Count);
                var updated = validEvent.NameTypeMaps.First();
                Assert.Equal(nameTypeMap.SubstituteNameTypeKey, updated.SubstituteNameTypeKey);
            }
        }
    }

    public class NameTypeMapMaintenanceFixture : IFixture<NameTypeMapMaintenance>
    {
        public NameTypeMapMaintenanceFixture()
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();

            Subject = new NameTypeMapMaintenance(WorkflowEventInheritanceService);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public NameTypeMapMaintenance Subject { get; }
    }
}