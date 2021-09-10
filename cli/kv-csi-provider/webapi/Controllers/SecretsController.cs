using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace webapi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SecretsController : ControllerBase
    {
        private readonly ILogger<SecretsController> _logger;
        private readonly IConfiguration configuration;

        public SecretsController(ILogger<SecretsController> logger, IConfiguration configuration)
        {
            _logger = logger;
            this.configuration = configuration;
        }

        [HttpGet("{key}")]
        public string Get([FromRoute] string key)
        {
            return configuration.GetValue<string>(key);
        }
    }
}
