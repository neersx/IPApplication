using System;
using InprotechKaizen.Model.Components.Cases.Filing.Electronic;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web
{
    public interface IEFilingCompatibility
    {
        void Check();
        bool Status { get; set; }
    }

    public class EFilingCompatibility : IEFilingCompatibility
    {
        readonly Func<IDbArtifacts> _dbArtifacts;
        public bool Status { get; set; }

        public EFilingCompatibility(Func<IDbArtifacts> dbArtifacts)
        {
            _dbArtifacts = dbArtifacts;
        }

        public void Check() => Status = _dbArtifacts().Exists(ListCaseEfilingPackageCommand.Command, SysObjects.StoredProcedure);
    }
}