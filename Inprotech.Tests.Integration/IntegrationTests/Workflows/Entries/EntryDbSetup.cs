using System.Linq;
using AutoMapper;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    public class EntryDbSetup : DbSetup
    {
        public TopicControl CreateStep(string name, string title = null, string usertip = null, string filter1Name = null, string filter1Value = null, string filter2Name = null, string filter2Value = null, bool? inherited = false, bool? mandatory = false)
        {
            var topicControl = new TopicControl(name)
            {
                TopicSuffix = Fixture.String(20), /* bypass error for now */
                IsInherited = inherited.GetValueOrDefault(),
                IsMandatory = mandatory.GetValueOrDefault(),
                ScreenTip = usertip,
                Title = title
            };

            if (!string.IsNullOrWhiteSpace(filter1Name))
            {
                topicControl.Filter1Name = filter1Name;
                topicControl.Filter1Value = filter1Value;
            }

            if (!string.IsNullOrWhiteSpace(filter2Name))
            {
                topicControl.Filter2Name = filter2Name;
                topicControl.Filter2Value = filter2Value;
            }

            return topicControl;
        }
    }

    public static class TopicExtensions
    {
        public static TopicControl Clone(this TopicControl source)
        {
            var config = new MapperConfiguration(cfg =>
                                                 {
                                                     cfg.CreateMap<TopicControl, TopicControl>()
                                                        .ForMember(dest => dest.Filters, opt => opt.MapFrom(src => src.Filters))
                                                        .ForMember(dest => dest.Filter1Name, opt => opt.Ignore())
                                                        .ForMember(dest => dest.Filter1Value, opt => opt.Ignore())
                                                        .ForMember(dest => dest.Filter2Value, opt => opt.Ignore())
                                                        .ForMember(dest => dest.Filter2Name, opt => opt.Ignore())
                                                        .ConstructUsing(x => new TopicControl(x.Name));

                                                     cfg.CreateMap<TopicControlFilter, TopicControlFilter>();
                                                     cfg.CreateMissingTypeMaps = true;
                                                 });
            var mapper = config.CreateMapper();

            return mapper.Map<TopicControl, TopicControl>(source);
        }
    }

    public static class CriteriaExtensions
    {
        public static DataEntryTask FirstEntry(this Criteria criteria)
        {
            return criteria.DataEntryTasks.First();
        }

        public static void QuickAdd(this DataEntryTask entry, params Event[] events)
        {
            DbSetup.Do(setup =>
                       {
                           for (var i = 0; i < events.Length; i++)
                               setup.Insert(new AvailableEvent
                                            {
                                                CriteriaId = entry.Criteria.Id,
                                                EventId = events[i].Id,
                                                DataEntryTaskId = entry.Id,
                                                DisplaySequence = (short) i,
                                                Inherited = 1
                                            });
                       }
                      );
        }

        public static TopicControl AddStep(this DataEntryTask entry, string name, string title = null, string usertip = null, string filter1Name = null, string filter1Value = null, string filter2Name = null, string filter2Value = null, bool? inherited = false, bool? mandatory = false)
        {
            return DbSetup.Do(setup =>
                              {
                                  var windowControl = setup.DbContext.Set<WindowControl>().SingleOrDefault(_ => (_.CriteriaId == entry.CriteriaId) && (_.EntryNumber == entry.Id) && (_.Name == "WorkflowWizard")) ??
                                                      setup.DbContext.Set<WindowControl>().Add(new WindowControl(entry.CriteriaId, entry.Id, "WorkflowWizard"));

                                  setup.DbContext.SaveChanges();

                                  var topic = new TopicControl(name)
                                  {
                                      TopicSuffix = Fixture.String(20), /* bypass error for now */
                                      IsInherited = inherited.GetValueOrDefault(),
                                      IsMandatory = mandatory.GetValueOrDefault(),
                                      ScreenTip = usertip,
                                      Title = title,
                                      RowPosition = (short) windowControl.TopicControls.Count
                                  };

                                  windowControl.TopicControls.Add(topic);
                                  setup.DbContext.SaveChanges();

                                  if (!string.IsNullOrWhiteSpace(filter1Name))
                                  {
                                      topic.Filter1Name = filter1Name;
                                      topic.Filter1Value = filter1Value;
                                  }

                                  if (!string.IsNullOrWhiteSpace(filter2Name))
                                  {
                                      topic.Filter2Name = filter2Name;
                                      topic.Filter2Value = filter2Value;
                                  }

                                  setup.DbContext.SaveChanges();

                                  return topic;
                              });
        }

        public static void QuickAddSteps(this DataEntryTask entry, params TopicControl[] topicControls)
        {
            DbSetup.Do(setup =>
                       {
                           var windowControl = setup.DbContext.Set<WindowControl>().SingleOrDefault(_ => (_.CriteriaId == entry.CriteriaId) && (_.EntryNumber == entry.Id) && (_.Name == "WorkflowWizard")) ??
                                                     setup.DbContext.Set<WindowControl>().Add(new WindowControl(entry.CriteriaId, entry.Id, "WorkflowWizard"));

                           setup.DbContext.SaveChanges();

                           var maxPosition = windowControl.TopicControls.Any() ? windowControl.TopicControls.Max(_ => _.RowPosition) : (short)1;

                           foreach (var t in topicControls)
                           {
                               t.RowPosition = maxPosition++;
                               windowControl.TopicControls.Add(t);
                           }

                           setup.DbContext.SaveChanges();
                       });
        }
    }
}