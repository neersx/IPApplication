using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    public class ScreenCriteriaBuilder : Builder
    {
        WindowControl _windowControl;

        bool _alreadyCreated;

        public ScreenCriteriaBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public ScreenCriteriaBuilder Create(Case @case, out int criteriaId, string program = KnownCasePrograms.CaseEntry)
        {
            if (_alreadyCreated) throw new InvalidOperationException("Create should only be called once to ensure no unintended polution to the Screen Criterion being created!");

            var existing = DbContext.Set<Criteria>()
                                    .SingleOrDefault(_ => _.PurposeCode == CriteriaPurposeCodes.WindowControl
                                                          && _.CountryId == @case.Country.Id
                                                          && _.CaseTypeId == @case.TypeId
                                                          && _.PropertyTypeId == @case.PropertyType.Code
                                                          && _.ProgramId == program
                                                          && _.RuleInUse == 1
                                                          && _.PropertyUnknown == 0
                                                          && _.CategoryUnknown == 0
                                                          && _.SubtypeUnknown == 0);
            if (existing != null)
            {
                // Should set existing rule to not in use.
                existing.RuleInUse = 0;
            }

            var criteria = InsertWithNewId(new Criteria
                       {
                           Description = Fixture.Prefix(Fixture.String(3)),
                           PurposeCode = CriteriaPurposeCodes.WindowControl,
                           CountryId = @case.Country.Id,
                           CaseTypeId = @case.TypeId,
                           PropertyTypeId = @case.PropertyType.Code,
                           ProgramId = program,
                           RuleInUse = 1,
                           PropertyUnknown = 0,
                           CategoryUnknown = 0,
                           SubtypeUnknown = 0
                       });

            criteriaId = criteria.Id;
            var critId = criteriaId;
            _windowControl = DbContext.Set<WindowControl>()
                                      .SingleOrDefault(_ => _.CriteriaId == critId
                                                            && _.Name == KnownCaseScreenWindowNames.CaseDetails
                                                            && _.IsInherited == false
                                                            && _.EntryNumber == null)
                             ?? Insert(new WindowControl
                             {
                                 CriteriaId = criteriaId,
                                 Name = KnownCaseScreenWindowNames.CaseDetails,
                                 IsInherited = false,
                                 EntryNumber = null
                             });

            DbContext.Reload(_windowControl);

            _alreadyCreated = true;

            return this;
        }

        public ScreenCriteriaBuilder CreateNameScreen(Name name, out int nameCriteriaId, string program = KnownNamePrograms.NameEntry)
        {
            if (_alreadyCreated) throw new InvalidOperationException("Create should only be called once to ensure no unintended population to the Screen Criterion being created!");

            var countryId = name.PostalAddress()?.Country?.Id; 

            var existing = DbContext.Set<NameCriteria>()
                                    .SingleOrDefault(_ => _.PurposeCode == CriteriaPurposeCodes.WindowControl
                                                          && _.CountryId == countryId
                                                          && _.UsedAsFlag == name.UsedAs
                                                          && _.SupplierFlag == name.SupplierFlag
                                                          && _.ProgramId == program
                                                          );
            if (existing != null)
            {
                // Should set existing rule to not in use.
                existing.RuleInUse = 0;
            }

            var nameCriteria = Insert(new NameCriteria
                       {
                           Description = Fixture.Prefix(Fixture.String(3)),
                           PurposeCode = CriteriaPurposeCodes.WindowControl,
                           CountryId = countryId,
                           ProgramId = program,
                           RuleInUse = 1,
                           UsedAsFlag = name.UsedAs,
                           SupplierFlag = name.SupplierFlag,
                           Id = Fixture.Integer(),
                           DataUnknown = 1,
                           ProfileId = null
                       });

            nameCriteriaId = nameCriteria.Id;
            var nameCritId = nameCriteriaId;
            _windowControl = DbContext.Set<WindowControl>()
                                      .SingleOrDefault(_ => _.NameCriteriaId == nameCritId
                                                            && _.Name == KnownNameScreenWindowNames.NameDetails
                                                            && _.IsInherited == false
                                                            && _.EntryNumber == null)
                             ?? Insert(new WindowControl
                             {
                                 NameCriteriaId = nameCriteriaId,
                                 Name = KnownNameScreenWindowNames.NameDetails,
                                 IsInherited = false,
                                 EntryNumber = null
                             });

            DbContext.Reload(_windowControl);

            _alreadyCreated = true;

            return this;
        }

        public ScreenCriteriaBuilder WithElementControl(string topicName, string fieldName, string fieldLabel, bool isHidden = false)
        {
            var topic = _windowControl.TopicControls.Single(_ => _.Name == topicName);

            InsertWithNewId(new ElementControl {ElementName = fieldName, FullLabel = fieldLabel, IsHidden = isHidden, TopicControlId = topic.Id});
            return this;
        }

        public ScreenCriteriaBuilder WithTopicControl(string topicName)
        {   
            InsertWithNewId(new TopicControl(topicName) {WindowControlId = _windowControl.Id});
            return this;
        }

        public ScreenCriteriaBuilder WithTopicControlsInTab(string tabName, string tabTitle, params TopicControlBuilder[] topicControlBuilders)
        {
            var tab = Insert(new TabControl { WindowControlId = _windowControl.Id, Name = tabName, Title = tabTitle});

            foreach (var builder in topicControlBuilders)
            {
                InsertWithNewId(builder.Build(_windowControl, tab));

                builder.TabId = tab.Id;
            }
            
            return this;
        }
    }

    public class TopicControlBuilder
    {
        public string TopicName { get; set; }

        public string TopicTitle { get; set; }

        public Dictionary<string, string> Filters { get; set; }

        public int TabId { get; set; }

        public TopicControl Build(WindowControl windowControl, TabControl tab)
        {
            var topicControl = new TopicControl(windowControl, tab, TopicName)
            {
                Title = TopicTitle
            };

            foreach (var filter in Filters ?? new Dictionary<string, string>())
            {
                topicControl.Filters.Add(new TopicControlFilter(filter.Key, filter.Value));
            }

            return topicControl;
        }

        public TopicControlBuilder()
        {
            
        }

        public TopicControlBuilder(string topicName) : this()
        {
            TopicName = topicName;
        }

        public TopicControlBuilder(string topicName, string filterName, string filterValue) : this(topicName)
        {
            Filters = new Dictionary<string, string>
            {
                { filterName, filterValue }
            };
        }
    }
}