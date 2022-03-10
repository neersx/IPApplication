using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Setup.IpPlatformTester
{
    class Program
    {
        static int Main(string[] args)
        {
            return MainAsync(args);
        }

        static int MainAsync(string[] args)
        {
            if (args.Length> 0 && !string.IsNullOrWhiteSpace(args[0]))
            {
                var keyValues = JsonConvert.DeserializeObject<Dictionary<string, string>>(args[0]);
                new ConfigurationSettings().AddOrUpdateAppSetting(keyValues);
            }

            return new IpPlatformTester().Test() ? 0 : -1;
        }
    }
}