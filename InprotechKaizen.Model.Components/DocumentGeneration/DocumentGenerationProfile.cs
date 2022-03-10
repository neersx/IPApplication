using AutoMapper;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.DocumentGeneration
{
    public class DocumentGenerationProfile : Profile
    {
        public DocumentGenerationProfile()
        {
            CreateMap<CaseActivityRequest, CaseActivityHistory>()
                .IgnoreAllPropertiesWithAnInaccessibleSetter()
                .ForPath(x => x.LastModified, y => y.Ignore());
        }
    }
}