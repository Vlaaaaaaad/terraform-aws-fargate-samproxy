Sampler = "DynamicSampler"

%{ for sampler in samplers ~}
  [SamplerConfig.${sampler.dataset_name}]
  %{ for option in sampler.options ~}
    ${option.name} = "${option.value}"
  %{ endfor ~}
%{ endfor ~}
