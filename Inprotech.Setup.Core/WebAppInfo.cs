using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core
{
    public class WebAppInfo
    {
        public WebAppInfo(string rawPath, IEnumerable<string> features, SetupSettings settings, IEnumerable<InstanceComponentConfiguration> componentConfigurations)
        {
            if (rawPath == null) throw new ArgumentNullException(nameof(rawPath));

            Settings = settings;
            ComponentConfigurations = componentConfigurations;

            FullPath = Helpers.NormalizePath(rawPath);
            InstanceName = Helpers.GetInstanceName(rawPath);
            Features = features ?? Enumerable.Empty<string>();
        }

        public string FullPath { get; }

        public string InstanceName { get; }

        public int? InstanceNo
        {
            get
            {
                var legacyInstancePattern = new Regex(@"instance-([0-9]*)$");

                if (legacyInstancePattern.IsMatch(InstanceName))
                    return int.Parse(InstanceName.Split('-')[1]);

                return null;
            }
        }

        public SetupSettings Settings { get; }

        public IEnumerable<InstanceComponentConfiguration> ComponentConfigurations { get; }

        public IEnumerable<string> Features { get; }

        //When the instance folder exists with some files but not the configuration file
        public bool IsBrokenInstance { get; private set; }

        public WebAppInfo MarkBroken()
        {
            IsBrokenInstance = true;
            return this;
        }
    }
}