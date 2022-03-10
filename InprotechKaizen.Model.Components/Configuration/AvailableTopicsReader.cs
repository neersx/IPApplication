using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration
{
    public interface IAvailableTopicsReader
    {
        IQueryable<AvailableTopic> Retrieve();
    }

    public class AvailableTopicsReader : IAvailableTopicsReader
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public AvailableTopicsReader(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IQueryable<AvailableTopic> Retrieve()
        {
            var culture = _preferredCultureResolver.Resolve();

            var allScreens = _dbContext.Set<Screen>();
            var webScreens = _dbContext.Set<TopicUsage>();

            return from a in allScreens
                   join w in webScreens on new {Name = a.ScreenName} equals new {Name = w.TopicName} into w1
                   from w in w1.DefaultIfEmpty()
                   select new AvailableTopic
                          {
                              Key = a.ScreenName,
                              DefaultClassicTitle = DbFuncs.GetTranslation(a.ScreenTitle, null, a.ScreenTitleTId, culture),
                              DefaultWebTitle = w != null ? DbFuncs.GetTranslation(w.TopicTitle, null, w.TopicTitleTId, culture) : null,
                              IsWebEnabled = w != null,
                              Type = w != null ? w.TopicType : a.ScreenType
                          };
        }
    }

    public class AvailableTopic
    {
        public AvailableTopic()
        {
            
        }

        public AvailableTopic(string screenName)
        {
            Key = screenName;
        }

        public string Key { get; set; }

        public string DefaultTitle => DefaultWebTitle ?? DefaultClassicTitle;

        public string DefaultClassicTitle { get; set; }

        public string DefaultWebTitle { get; set; }

        public string Type { get; set; }

        public bool IsWebEnabled { get; set; }
    }
}