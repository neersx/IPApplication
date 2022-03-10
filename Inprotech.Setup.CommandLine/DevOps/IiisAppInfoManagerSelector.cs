using System;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.CommandLine.DevOps
{
    public class IiisAppInfoManagerSelector
    {
        readonly Func<string, IIisAppInfoManager> _selector;

        public IiisAppInfoManagerSelector(Func<string, IIisAppInfoManager> selector)
        {
            _selector = selector;
        }

        public IIisAppInfoManager Select(string profile)
        {
            return _selector(profile);
        }
    }
}