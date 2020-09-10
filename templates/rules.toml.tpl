Sampler = "DynamicSampler"

%{ for sampler in samplers ~}
  [SamplerConfig.${sampler.dataset_name}]
  %{ for option in sampler.options ~}
    ${option.name} = ${ try(
                          tonumber(option.value),
                          tobool(option.value),
                          length(regexall("\\[", option.value)) == 0 ? "\"${option.value}\"" : option.value,
                      )}
  %{ endfor ~}
%{ endfor ~}
