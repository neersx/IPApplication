using System;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Infrastructure.Web
{
    public interface ISearchBar
    {
        object SearchAccess();
    }

    public class SearchBar : ISearchBar
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public SearchBar(ITaskSecurityProvider taskSecurityProvider)
        {
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");
            _taskSecurityProvider = taskSecurityProvider;
        }

        public object SearchAccess()
        {
            return new
            {
                CanAccessCaseSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.AdvancedCaseSearch),
                CanAccessQuickCaseSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.QuickCaseSearch)
            };
        }
    }
}