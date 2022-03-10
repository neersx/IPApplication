using System.Linq;
using AutoMapper;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public class EntryControlMaintenanceProfile : Profile
    {
        public EntryControlMaintenanceProfile()
        {
            CreateMap<WorkflowEntryControlSaveModel, DataEntryTask>();
            CreateMap<EntryEventDelta, AvailableEvent>();

            CreateMap<AvailableEvent, EntryEventReorderSource>()
                .ForMember(dest => dest.Description, opt => opt.MapFrom(src => src.EventName));

            CreateMap<TopicControl, StepReorderSource>()
                .ForMember(dest => dest.DisplaySequence, opt => opt.MapFrom(src => src.RowPosition))
                .ForMember(dest => dest.Hash, opt => opt.MapFrom(src => src.HashCode()));

            CreateMap<DataEntryTask, EntryReorderSouce>()
                .ForMember(dest => dest.EntryId, opt => opt.MapFrom(src => src.Id))
                .ForMember(dest => dest.EntryEvents, opt => opt.MapFrom(src => src.AvailableEvents))
                .ForMember(dest => dest.Steps, opt =>
                           {
                               opt.Condition(src => src.WorkflowWizard != null);
                               opt.MapFrom(src => src.WorkflowWizard.TopicControls);
                           });

            CreateMap<StepCategory, TopicControlFilter>();
            CreateMap<StepDelta, TopicControl>()
                .ForMember(dest => dest.Filters, opt => opt.MapFrom(src => src.Categories.Select(_ => _.ConvertToFilter())))
                .ForMember(dest => dest.Filter1Name, opt => opt.Ignore())
                .ForMember(dest => dest.Filter1Value, opt => opt.Ignore())
                .ForMember(dest => dest.Filter2Value, opt => opt.Ignore())
                .ForMember(dest => dest.Filter2Name, opt => opt.Ignore());
        }
    }
}