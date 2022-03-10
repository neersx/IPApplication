using System;
using System.Collections.Generic;
using System.IO;
using System.Security.AccessControl;
using System.Security.Principal;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class SetFilePermission : ISetupAction
    {
        public string Description => "Set file permission";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var serviceUser = (string)context["ServiceUser"];
            
            var administrators = new SecurityIdentifier("S-1-5-32-544").Translate(typeof(NTAccount)).Value;

            var users = new[] {serviceUser, administrators};

            Set(context.InprotechServerPhysicalPath(), users, eventStream);
            Set(context.InprotechIntegrationServerPhysicalPath(), users, eventStream);
            Set(context.InprotechStorageServicePhysicalPath(), users, eventStream);
        }

        static void Set(string path, IEnumerable<string> users, IEventStream eventStream)
        {
            if (!Directory.Exists(path))
            {
                throw new SetupFailedException($"Could not find destination directory {path}");
            }

            foreach (var user in users)
            {
                eventStream.PublishInformation($"Grant file permissions for {user}");
                var acl = Directory.GetAccessControl(path);
                acl.SetAccessRuleProtection(true, true);
                acl.AddAccessRule(
                                  new FileSystemAccessRule(
                                      user,
                                      FileSystemRights.FullControl,
                                      InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
                                      PropagationFlags.None,
                                      AccessControlType.Allow));

                Directory.SetAccessControl(path, acl);
            }
        }
    }
}